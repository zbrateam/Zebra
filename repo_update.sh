#!/bin/bash

main() {
	argc=$#
	argv=($@)
#	for (( i = 0; i < $argc; i++ )); do
#		echo "argv[$i] = ${argv[$i]}"
#	done

	# Build existent packages list (filenames and package names), filtered so only the latest version is listed
	oldpath=repo/pkgfiles
	fullpkglist=()
	o=0
	for f in `ls $oldpath`; do
		fullpkglist[$o]="$f"
		o=$((o+1))
	done
#	echo All packages
#	for (( i = 0; i < ${#fullpkglist[@]}; i++ )); do
#		echo - ${fullpkglist[$i]} \(${fullpkglist[$i]}\)
#	done

	oldpkglist=()
	oldpkgnames=()
	prevname=""
	prevpkg=""
	k=0
	for (( i = 0; i < $o; i++ )); do
		name=`dpkg-deb -f $oldpath/${fullpkglist[$i]} Name | sed "s/\r//"`
		name_=`printf "\"%s\"\n" "$name"`
#printf "\033[32m%d::%s::%s\033[0m\n" "$i" "$name_" "${fullpkglist[$i]}"
		if [[ ! i -eq 0 ]]; then
			if [[ $name_ != $prevname ]]; then
				k=$((k+1))
			fi
		fi
		prevname=$name_
#printf "\033[35m%s=%s\033[0m\n" "oldpkglist[$k]" "${fullpkglist[$i]}"
		oldpkglist[$k]=${fullpkglist[$i]}
#printf "\033[36m%s=%s\033[0m\n" "oldpkgnames[$k]" "$name_"
		oldpkgnames[$k]=$name_
	done
#	echo Old packages
#	for (( i = 0; i < ${#oldpkgnames[@]}; i++ )); do
#		echo - ${oldpkgnames[$i]} \(${oldpkglist[$i]}\)
#	done

	newpath=repo/newpackages
	pkglist=()
	N=0
	for f in `ls $newpath`; do
		pkglist[$N]="$f"
		N=$((N+1))
	done
	newpkglist=()
	newpkgnames=()
	n=0
	newpkglist=()
	updpkgnames=()
	u=0
	for (( i = 0; i < $N; i++ )); do
		name=`dpkg-deb -f $newpath/${pkglist[$i]} Name | sed "s/\r//"`
		name_=`printf "\"%s\"\n" "$name"`
		s=0
		for (( j = 0; j < ${#oldpkglist[@]}; j++ )); do
			if [[ $name_ == ${oldpkgnames[$j]} ]]; then
				s=1
				break;
			fi
		done
		if [[ s -eq 1 ]]; then
			updpkglist[$u]=${pkglist[$i]}
			updpkgnames[$u]=$name_
			u=$((u+1))
		else
			newpkglist[$n]=${pkglist[$i]}
			newpkgnames[$n]=$name_
			n=$((n+1))
		fi
	done
#	echo Updated packages
#	for (( i = 0; i < ${#updpkgnames[@]}; i++ )); do
#		echo - ${updpkgnames[$i]} \(${updpkglist[$i]}\)
#	done
#	echo New packages
#	for (( i = 0; i < ${#newpkgnames[@]}; i++ )); do
#		echo - ${newpkgnames[$i]} \(${newpkglist[$i]}\)
#	done

	m=`printf "%s" "Updated packages:"`
	for (( i = 0; i < ${#updpkgnames[@]}; i++ )); do
		v_old=`dpkg-deb -f $oldpath/${oldpkglist[$i]} Version | sed "s/\r//"`
		v_new=`dpkg-deb -f $newpath/${updpkglist[$i]} Version | sed "s/\r//"`
		m=`printf "%s\n- %s (%s -> %s)\n" "$m" "${updpkgnames[$i]}" "$v_old" "$v_new"`
		pkg=${updpkglist[$i]}
#echo \
		mv $newpath/$pkg $oldpath/$pkg
#echo \
		git add $oldpath/$pkg
	done
	m=`printf "%s\n\n%s\n" "$m" "New packages:"`
	for (( i = 0; i < ${#newpkgnames[@]}; i++ )); do
		v=`dpkg-deb -f $newpath/${newpkglist[$i]} Version | sed "s/\r//"`
		m=`printf "%s\n- %s (%s)\n" "$m" "${newpkgnames[$i]}" "$v"`
		pkg=${newpkglist[$i]}
#echo \
		mv $newpath/$pkg $oldpath/$pkg
#echo \
		git add $oldpath/$pkg
	done

	# Build Release, Packages and Packages.bz2
#echo \
	cd repo
#echo \
	make
#echo \
	cd ..
#echo \
	git add repo/Packages* repo/Release

	# Push changes to repository
#printf "\033[32m%s\033[0m\n" "$m"
	date_=`date -u +%F_%T`
#echo \
	git commit -m "$date_ update" -m "$m"
#echo \
	git push

}

main $0 $@
