
clear
cap cd "C:/Users/wb585866/OneDrive - WBG/Documents/test"


sysuse auto, clear
scatter price mpg 
graph export ./figures/figure1.png, replace wid(1000)
scatter length weight
graph export ./figures/figure2.png, replace wid(1000)
scatter price weight
graph export ./figures/figure3.png, replace wid(1000)
scatter length mpg
graph export ./figures/figure4.png, replace wid(1000)

NO THIS IS MY CONTRIBUTION AS USER 1

! echo # expert-system >> README.md
! git init
! git add README.md
! git commit -m "first commit"
! git branch -M main
! git remote add origin https://github.com/NathanBarzola/expert-system.git
! git push -u origin main

! git remote add origin https://github.com/NathanBarzola/expert-system.git
! git branch -M main
! git push -u origin main

! git remote add origin "https://github.com/NathanBarzola/expert-system.git"
! git status
! git add --all
! git commit -m "minor fixes"
! git push



file close _all
file open git using mygit.bat, write replace
file write git "git remote add origin " `"""' "https://github.com/NathanBarzola/expert-system.git" `"""' _n
 file write git "git add --all" _n
 file write git "git commit -m "
 file write git `"""' "minor fixes" `"""' _n
 file write git "git push" _n
file close git