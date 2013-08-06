# Devops script 
# Author: Sibi <sibi@psibi.in>

cp -v .alias ~/.alias
cp -v .global_ignore ~/.global_ignore
cp -v init.el ~/.emacs.d/init.el

git config --global core.excludefile ~/.global_ignore
cat ./.bashrc >> ~/.bashrc
