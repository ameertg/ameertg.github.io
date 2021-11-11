---
layout: single
classes: wide
title:  "above water"
category: music
---

I've been thinking a lot about discomfort. The idea of putting myself in situations where I'm forced to confront my own limitations. In every story, there is a character at ease in her own environment, stagnant and unaware of her own potential. The story begins when that ease is disturbed; a catalyst emerges from some internal dynamics, external forces or a combination of both which pushes against the inertia generated by comfort. And only in the face of this pressure can she sense the contours of her own self, recognise her capabilities and push against them to redefine their shape. It is only against this force that the amorphous blob is shaped and hardened.

Sound, much like the catalysts of stories is a change in pressure around us. It pervades our environment and is constantly shaping our interactions with it. And so, the question I tried to answer in making this piece is how can I shape the sound to press on the boundaries of my *self*. The goal was to create something so heavy, so oppressive, that it would force me out of the lull of time passing. To force me to confront myself and reckon with the things that I'm afraid of. In this way, at least to me, when you face ugliness and harshness head on, what emerges is always a thing of beauty.

{% assign songs = site.data.soundcloud | where: song.title, 'title'%}
{% for song in songs %}
  <iframe width="100%" height="3%" scrolling="yes" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/{{song.track}}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="https://soundcloud.com/minor6" title="ameertg" target="_blank" style="color: #cccccc; text-decoration: none;">ameertg</a> · <a href="{{song.url}}" title="{{song.title}}" target="_blank" style="color: #cccccc; text-decoration: none;">{{song.title}}</a></div><br>
{% endfor %}