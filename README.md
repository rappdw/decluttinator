# decluttinator - Remove the cruft that builds up in your Git repositories over time

It's common to experience repo bloat for long lived repos. You may have tens of thousands of commits and find that
the full history provides more drag than lift. You may have inadvertently committed large binaries in the past and 
haven't taken the time to remove them properly.

Decluttinator is a set of utilities that automate common patterns used to declutter long lived git repos.

## Pre-requisites

There are a few useful additions to git to assist in determining cruft and removing it. Depending on your usage of
decluttinator, they may not be required.

1. Install [git-sizer](https://github.com/github/git-sizer) (`brew install git-sizer` on OSX, useful for determining the amount of clutter in your repo)
2. Install [git-filter-repo](https://github.com/newren/git-filter-repo) (`brew install git-filter-repo` on OSX, useful for removing clutter from your repo)

## Usage

### Extensive History

Over time, you may find that the extent of your repository's history causes common git operations (clone, etc.) to
run uncomfortably long. In fact, there is a section in [Pro Git | Replace](https://git-scm.com/book/en/v2/Git-Tools-Replace)
that uses this use case as motivation for understanding `git replace`.

The `split-repo.sh` script implements a pattern for splitting your repo into a historical version and a version
for new development. Should you want to view new development in the context of the full history, `join-repo.sh`
provides the pattern to allow you to do so.

To run, `split-repo.sh`, you must first create a configuration file that specifies the following values:

```shell
REPO=<fully qualified repository URL or path... the one with the extensive history>
HISTORICAL_REPO=<fully qualified path that will be created to hold the historical version of the repo>
NEW_REPO=<fully qualified path to the new, ligth-weight repo that will be created>
BRANCHES=<space seperated list of branches that should be split from the REPO, usually "main", possibly others>
```

With this configuration file in place, split-repo can be run as follows: `split-repo.sh <config_file>`

### Large Binary Files

If you have large binary files in your repository, over time, this becomes a significant drag. Git is not
well suited to handle binary files. While you may want to consider using [git-lfs](), the optimal solution
is to utilize a package manager for your binaries. In any case, [git-filter-repo]() is available to filter any
large binaries in your repository. `slim-repo.sh` can be used to automatically do this. To run `slim-repo.sh`, 
you must first create a configuration file with the following values:

```shell
NEW_REPO=<fully qualified path to the new, ligth-weight repo that will be created>
SLIMMED_PATH=<path of the repo that has been 'slimmed'>
FILTER_EXTENSIONS=<comma seperated string of .<extension>, e.g. ".exe,.dll">
FILTER_ADDITIONAL=<comma seperated string of additional paths that should be filtered>
```
