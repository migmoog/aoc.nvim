# Advent Of Code in Neovim

A convenient plugin for working on your advent of code solutions in neovim.

Includes features like:
 - Viewing puzzle descriptions in the editor
 - Automatically downloading puzzle inputs
 - A spec for you to test your solutions within neovim

## How to set up
Advent of Code uses OAuth for user authentication. In order to communicate with the API for data that's
specific to you, the plugin needs a cookie to authenticate. To set this up you must:
 1. Log into AOC in your web browser
 2. Run `:AocLogin` to give the plugin your cookie 
 3. Find the cookie and copy it into the field
 4. Work on from there!
