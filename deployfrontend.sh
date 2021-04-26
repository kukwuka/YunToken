rsync -r src/ docs/
rsync build/contracts/* docs/
git add .
git commit -m
git push -u origin master