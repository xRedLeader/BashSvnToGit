#!/bin/bash

echo "Please enter the URL to the SVN repo:"
read svnrepo
echo "Please enter the URL to the GIT repo:"
read giturl

mkdir $HOME/temp/
cd $HOME/temp/

svn checkout $svnrepo

cd $( ls -ltrd */ | tail -1 | awk '{ print $10 }' )

svn log -q | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > authors-transform.txt

git svn clone $svnrepo --no-metadata -A authors-transform.txt --stdlayout ~/temp2


cd $HOME/temp2
git svn show-ignore > .gitignore
git add .gitignore
git commit -m 'Convert svn:ignore properties to .gitignore.'

git init --bare $HOME/new-bare.git
cd $HOME/new-bare.git
git symbolic-ref HEAD refs/heads/trunk

cd $HOME/temp2
git remote add bare $HOME/new-bare.git
git config remote.bare.push 'refs/remotes/*:refs/heads/*'
git push bare

cd $HOME/new-bare.git
git branch -m origin/trunk origin/master


cd $HOME/new-bare.git
git for-each-ref --format='%(refname)' refs/heads/tags |
cut -d / -f 4 |
while read ref
do
  git tag "$ref" "refs/heads/tags/$ref";
  git branch -D "tags/$ref";
done


cd $HOME/temp2
git remote add gitrepo $giturl
git push -u gitrepo master

rm -rf $HOME/temp2
rm -rf $HOME/temp
rm -rf $HOME/new-bare.git
