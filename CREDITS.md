# Credits

## Author

**Christopher Arnold** ([@ncubeeight](https://github.com/ncubeeight)) conceived, directed, tested and maintains
this project. It came from more than a decade of using Google Glass for photography,
and the wish to keep the Enterprise Edition 2 useful after Google ended support.

## Built with Claude Code by Anthropic

This software was developed in collaboration with
[Claude Code](https://claude.com/claude-code), the agentic coding tool from
[Anthropic](https://www.anthropic.com), at the author's request and under his direction.

Thank you to Anthropic and the Claude Code team for building a tool that made it practical to
bring an orphaned device back into everyday use.

### What Claude Code contributed

**Original version (August 2026)**
- The `adb`-based watcher that detects a Glass EE2 over USB and imports new photos and videos
- Size verification before archiving, and the non-destructive `.imported/` archive on the device
- The portable installer, uninstaller and LaunchAgent template

**Version 2 (October 2026), with Claude Opus 5.5**
- Diagnosed and fixed a bug where each connection imported only one photo and one video.
  The `adb shell` calls inside the import loop were reading the loop's own file list from stdin.
- Fixed partial copies left behind by an unplugged Glass, which caused those files to be skipped forever
- Built the native progress window, which shows the current file, a byte-accurate progress bar,
  time remaining and where files are saved
- Added notifications for completion, failed files and mid-import disconnects
- Packaged the project for other Mac users and wrote this documentation

Commits that Claude Code helped write carry a `Co-Authored-By: Claude` trailer in the git history.

## Acknowledgements

Thanks to the Google engineers who designed the Glass product line. Their hardware is still
going strong years after launch.

---

*This project is independent. It is not affiliated with, endorsed by or supported by Google or
Anthropic. Google Glass is a trademark of Google LLC. Claude and Claude Code are trademarks of
Anthropic, PBC.*
