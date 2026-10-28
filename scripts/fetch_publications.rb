#!/usr/bin/env ruby
# Pulls publications from OpenAlex (https://openalex.org) and writes
# _data/publications.yml, which the site renders on /publications.html.
#
# Manual corrections (local PDFs, nicer venue names, missing papers, hidden
# entries) live in _data/publication_overrides.yml and are merged in here.
#
#   ruby scripts/fetch_publications.rb
#
# Optional env: OPENALEX_API_KEY (raises the shared anonymous rate limit).

require "json"
require "net/http"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
OVERRIDES_PATH = File.join(ROOT, "_data", "publication_overrides.yml")
OUTPUT_PATH = File.join(ROOT, "_data", "publications.yml")

TYPE_LABELS = {
  "article" => "Journal article",
  "conference-paper" => "Conference paper",
  "book-chapter" => "Book chapter",
  "dissertation" => "PhD thesis",
  "preprint" => "Preprint",
}.freeze

def fetch_works(author_id)
  works = []
  cursor = "*"
  while cursor
    params = {
      "filter" => "authorships.author.id:#{author_id}",
      "per_page" => "100",
      "cursor" => cursor,
    }
    params["api_key"] = ENV["OPENALEX_API_KEY"] if ENV["OPENALEX_API_KEY"]
    uri = URI("https://api.openalex.org/works")
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    raise "OpenAlex returned HTTP #{res.code}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

    body = JSON.parse(res.body)
    works.concat(body["results"])
    cursor = body["results"].empty? ? nil : body.dig("meta", "next_cursor")
  end
  works
end

def bare_doi(doi)
  doi&.sub(%r{\Ahttps?://(dx\.)?doi\.org/}i, "")&.downcase
end

# OpenAlex stores abstracts as {word => [positions]}.
def abstract_from(index)
  return nil unless index

  words = []
  index.each { |word, positions| positions.each { |pos| words[pos] = word } }
  words.compact.join(" ")
end

def normalize(work, author_id)
  loc = work["primary_location"] || {}
  biblio = work["biblio"] || {}
  doi = bare_doi(work["doi"])
  pages = [biblio["first_page"], biblio["last_page"]].compact.uniq.join("–")

  {
    "id" => work["id"].split("/").last,
    "title" => work["title"],
    "authors" => work["authorships"].map do |a|
      { "name" => a.dig("author", "display_name"), "me" => a.dig("author", "id").to_s.end_with?(author_id) }
    end,
    "year" => work["publication_year"],
    "date" => work["publication_date"],
    "type" => work["type"],
    "venue" => loc.dig("source", "display_name"),
    "volume" => biblio["volume"],
    "pages" => pages.empty? ? nil : pages,
    "doi" => doi,
    "url" => doi ? "https://doi.org/#{doi}" : loc["landing_page_url"],
    "pdf" => loc["pdf_url"] || work.dig("open_access", "oa_url")&.then { |u| u if u.end_with?(".pdf") },
    "abstract" => abstract_from(work["abstract_inverted_index"]),
  }
end

# Overrides are keyed by DOI or OpenAlex work ID, case-insensitively.
def override_for(pub, overrides)
  overrides[pub["doi"]] || overrides[pub["id"].downcase] || {}
end

def title_key(title)
  title.to_s.downcase.gsub(/[^a-z0-9]/, "")
end

def bibtex(pub)
  first = pub["authors"].first&.fetch("name").to_s.split.last.to_s.downcase.gsub(/[^a-z]/, "")
  word = pub["title"].to_s.downcase.scan(/[a-z]{4,}/).first
  key = [first, pub["year"], word].compact.join

  kind, venue_field =
    case pub["type"]
    when "article" then ["article", "journal"]
    when "dissertation" then ["phdthesis", "school"]
    when "book-chapter" then ["incollection", "booktitle"]
    else ["inproceedings", "booktitle"]
    end

  fields = {
    "title" => pub["title"],
    "author" => pub["authors"].map { |a| a["name"] }.join(" and "),
    venue_field => pub["venue"],
    "volume" => pub["volume"],
    "pages" => pub["pages"]&.tr("–", "-")&.sub("-", "--"),
    "year" => pub["year"],
    "doi" => pub["doi"],
    "url" => pub["url"],
  }.reject { |_, v| v.nil? || v.to_s.empty? }

  lines = fields.map { |k, v| "  #{k} = {#{v}}" }
  "@#{kind}{#{key},\n#{lines.join(",\n")}\n}"
end

config = File.exist?(OVERRIDES_PATH) ? YAML.safe_load(File.read(OVERRIDES_PATH)) || {} : {}
author_id = config.fetch("openalex_author")
overrides = (config["overrides"] || {}).transform_keys { |k| bare_doi(k.to_s) }

begin
  works = fetch_works(author_id)
rescue StandardError => e
  warn "Could not fetch from OpenAlex (#{e.message}); keeping existing #{OUTPUT_PATH}."
  exit 1
end

pubs = works.map { |w| normalize(w, author_id) }

# Apply overrides, then drop hidden entries.
pubs = pubs.map { |pub| pub.merge(override_for(pub, overrides)) }
pubs.reject! { |pub| pub.delete("hide") }

# Manually listed papers that OpenAlex is missing.
(config["extra"] || []).each do |entry|
  pub = entry.dup
  pub["authors"] = pub["authors"].map { |name| { "name" => name.delete_prefix("*"), "me" => name.start_with?("*") } }
  pubs << pub
end

# OpenAlex sometimes lists a preprint and its published version separately;
# keep the published one.
pubs = pubs.group_by { |pub| title_key(pub["title"]) }.values.map do |group|
  group.min_by { |pub| [pub["type"] == "preprint" ? 1 : 0, pub["doi"] ? 0 : 1] }
end

pubs.each do |pub|
  pub["pdf"] = "/assets/pdfs/#{pub['pdf']}" if pub["pdf"] && !pub["pdf"].include?("/")
  pub["type_label"] ||= TYPE_LABELS.fetch(pub["type"], "Publication")
  pub["bibtex"] = bibtex(pub)
end

pubs = pubs.sort_by { |pub| (pub["date"] || pub["year"]).to_s }.reverse

header = "# Generated by scripts/fetch_publications.rb from OpenAlex. Do not edit by hand;\n" \
         "# put corrections in _data/publication_overrides.yml instead.\n"
yaml = header + pubs.to_yaml(line_width: -1)

if File.exist?(OUTPUT_PATH) && File.read(OUTPUT_PATH) == yaml
  puts "No changes (#{pubs.size} publications)."
else
  File.write(OUTPUT_PATH, yaml)
  puts "Wrote #{pubs.size} publications to #{OUTPUT_PATH}."
end
