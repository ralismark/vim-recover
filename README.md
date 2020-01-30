# Vim-Recover

> Note: Currently only supports Neovim

Show diff with recovered file, and automatically deletes outdated swapfiles.

When you open a file in Vim that wasn't saved properly (e.g. you accidentally killed vim), you'll get a popup notifying you of a swapfile, along with several options. This plugin automatically ignores this popup when nothing has changed/the swapfile is old, and otherwise shows the recovered version and the on-disk version side-by-side as a diff.

Inspired by [Recover.vim](https://github.com/chrisbra/Recover.vim).

## Installation

This plugin can be installed using most plugin managers. You can directly use the master branch - there are no special 'stable' or 'release' branches.

Once installed, this plugin should automatically work. There are no configuration options.

## Usage

When opening a file that needs recovery, two buffers will open:

- One with the file name: this is what was recovered
- One with `(on-disk pre-recovery)`: this is the contents of the actual file, before any recovery

You can save the recovered file to accept the recovered contents. The pre-recovery file is temporary - changes to this will not be saved.

If recovery is not needed (e.g. if the recovered version is the same as the on-disk version, or if the swapfile is old), you'll get a popup telling you that the old swapfile was deleted. 

(Experimental) I've also added a feature to detect if the recovered file is actually just open in another vim instance. However, this is unreliable and may not always trigger.
