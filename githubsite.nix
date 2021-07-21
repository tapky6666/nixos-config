{ fetchFromGitHub ? (import <nixpkgs> { }).fetchFromGitHub }:

import (fetchFromGitHub (builtins.fromJSON (builtins.readFile ./githubsite.json)))
{ }

