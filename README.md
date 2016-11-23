# gh - Navigate local github repositories

(A simple powershell command 'gh' to manage local git repos, inspired by this article:
https://medium.com/@dickeyxxx/the-best-code-ive-ever-written-afaf96f49535#.rb3saf7z4).

This is a simple powershell function to download git hub repos to a logical local folder structure,
navigate easily navigate that folder structure.

To use it, at the top of the file change the line that assigns the variable *$gitdir* to the folder
where you would like all of your local github repositories to be stored.

Then you can use as per the following examples:

`gh https://github.com/USER/REPO.git`

or

`gh USER REPO`

If a local copy of the repo https://github.com/USER/REPO.git does not exist,
download it to the folder $gitdir\USER\REPO. If a local copy _does_ exist,
cd to that local folder ($gitdir\USER\REPO).

`gh ID`

Search for any local repos with REPOID as the name of the user or repo.
ie. $gitdir\USER\REPO where either USER=ID or REPO=ID.
If a single repo matches ID, cd to that repo.
Otherwise, list all matching repos.

`gh`

List all local repos.


