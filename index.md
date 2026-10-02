---
layout: page
title: About
permalink: /
---

# Years with Google Glass

## Getting started

In 2014 the first version of Google Glass Explorer Edition was made public
in the US. As a photographer and world traveler, I thought this would be
useful in chronicling my travels and being used to create timelines for
complex journeys for later review.

## Three generations, ten years

Over 10 years I'd used the Explorer Edition and subsequently bought the
Enterprise Edition 1 and Enterprise Edition 2 updates to the product line.

## The deprecation

To make way for a future smart glass device powered by the new Gemini
tools (codenamed Astra at Google I/O 2024), the former Glass product line
was discontinued. All support from the Android App Store was removed at
this time, so that subsequently customers needed to use Android Debug
Bridge to interface with their device. This meant that millions of people
who owned the device would need to use Terminal command line to back up
their device.

Fortunately, Google Glass Explorer Edition and Enterprise Edition 1 had a
DCIM folder — standard to many camera-enabled devices — that allowed a Mac,
Linux, Chromebook, or Windows machine to back up photos by connecting over
USB. Enterprise Edition 2 deprecated use of DCIM and stored images on a
path specific to that device, such that a connected computer could not
read the images or movie files.

## Building the importer

The devices I bought still function very well. I wished to continue their
life without always having to use Terminal CLI to back up the device. So I
wanted to share this utility with others who own the device, to give them
a means to back up images and movies from their Enterprise Edition 2
Google Glasses.

## Looking ahead

I look forward to the release of Astra soon! But I'd like to say a special
thank you to all the engineers who made such a compelling product for
photographers. Still going strong after 12 years!

## Version 2: October 2026

The first release had a frustrating flaw: each time the Glass was plugged
in, it copied only one photo and one video, leaving the rest behind. Version
2 fixes that and imports everything in a single pass.

It also answers a question I kept asking myself while using it: *is anything
actually happening?* After you accept the USB debugging prompt, the Mac now
opens a progress window. It shows which file is being copied, how much is
left, and exactly where your photos and videos are being saved, with a
reminder to keep the Glass plugged in until it's done. If the Glass is
unplugged partway through, the importer says so and picks up where it left
off next time.

If you installed the first version, download the new one and run
`./install.sh` again to update.

## Try it

Grab the latest version from [`GlassEE2AutoImport.zip`](GlassEE2AutoImport.zip),
or browse the source in the [`GlassAutoImport`](https://github.com/ncubeeight/GoogleGlassEnterpriseEdition2AutoImporter/tree/main/GlassAutoImport)
folder. The [README](https://github.com/ncubeeight/GoogleGlassEnterpriseEdition2AutoImporter#readme)
has setup details.

## Credits

Built with [Claude Code](https://claude.com/claude-code) by Anthropic. See
[CREDITS.md](https://github.com/ncubeeight/GoogleGlassEnterpriseEdition2AutoImporter/blob/main/CREDITS.md)
for the full story of who did what.
