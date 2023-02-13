#!/usr/bin/env python
import argparse
import pathlib


def process_analysis(directory, extensions, additional):
    # parse string of comma seperated strings to an array of strings
    filtered_extensions = extensions.split(',')
    additional_filters = additional.split(',')
    filtered_paths = []
    # open directory/filter-repo/blob-shas-and-paths.txt
    with open(f"{directory}/blob-shas-and-paths.txt", "r") as f:
        # read file into a list of lines
        lines = f.readlines()
        # loop over each line
        for line in lines:
            if line.startswith("===") or line.startswith("Format:"):
                continue
            # split line into sha and path
            sha = line[2:42]
            paths = line[65:].strip()
            if paths.startswith("["):
                paths = paths[1:-1].split(", ")
            else:
                paths = [paths]
            # loop over each path and check extensions
            for path in paths:
                if path in additional_filters:
                    filtered_paths.append((paths, sha))
                    break
                extension = pathlib.Path(path).suffix
                if extension in filtered_extensions:
                    filtered_paths.append((paths, sha))
                    break
    filtered_paths.sort(key=lambda x: x[0][0])
    with open(f"{directory}/filtered_blobs.txt", "w") as blob_file, open(f"{directory}/filtered_files.csv", "w") as path_file:
        path_file.write("# file SHA-1, File Path(s)\n")
        for paths, sha in filtered_paths:
            blob_file.write(f"{sha}\n")
            path_file.write(f"{sha},{paths[0] if len(paths) == 1 else paths}\n")


if __name__ == "__main__":
    # parse input arguments
    parser = argparse.ArgumentParser()
    # add single argument which is directory to clean
    parser.add_argument("analysis_directory", help="directory that has output of 'git filter-repo --analyze'")
    parser.add_argument("extension_filters", help="a string of comma seperated .extension to filter",
                        default=".exe,.dll,.lib,.gz,.zip,.tar,.tgz,.bz2,.xz,.7z,.rar,.jar,.war,.ear,.msi,.msm,.mdb")
    parser.add_argument("additional_filters", help="a string of comma seperated pathname to filter", default="")
    args = parser.parse_args()
    # get directory to clean
    process_analysis(args.analysis_directory, args.extension_filters, args.additional_filters)

    print(f"Recommended blobs to remove can be found in: {args.analysis_directory}/filtered_blobs.txt")
    print(f"Recommended files to remove can be found in: {args.analysis_directory}/filtered_files.csv")
