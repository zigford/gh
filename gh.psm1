function get-githubrepo {
	Param(
		[string]$arg1,
		[string]$arg2
	)

	$gitdir = "c:\Scratch\drees\git"

	function localrepos {
		$repolist = @()
		$allusers = (Get-ChildItem -Directory -Path $gitdir).name
		foreach ($u in $allusers) {
			$udir = ($gitdir + "\" + $u)
			$allrepos = (Get-ChildItem -Directory -Path $udir).name
			foreach ($r in $allrepos) {
				$repolist += [PSCustomObject]@{
					user = $u
					repo = $r
				}
			}
		}
		return $repolist
	}

	function clone_repo($git_repo_uri, $user_path, $repo_path) {
		$ErrorActionPreference="SilentlyContinue"
		try {
			$stat = invoke-webrequest $git_repo_uri -ErrorAction Stop
		}
		catch {
			write-host "No such repository ${git_repo_uri}"
		}

		if ($stat.StatusCode -eq 200) {
			$ErrorActionPreference="Continue"
			if (-not (Test-Path($user_path))) {
				mkdir -force $user_path
			}

			git clone $git_repo_uri $repo_path
			if ($?) {
				write-host "Repo ${git_repo_uri} successfully cloned"
				# Success
				Return $True	
			}
			else {
				write-warning ("** Git failed with error")
				$RemoveRepo = Read-Host -Prompt "** Delete (probably incomplete) repo? (Y/N)"
				if ($RemoveRepo -match "y*") {
					Remove-Item -recurse $repo_path
				}
			}
		}
		# Fail
		return $False
	}

	function user_and_repo($user, $repo) {
		$user_path=$gitdir + "\" + $user
		$repo_path=$user_path + "\" + $repo

		if (Test-Path($repo_path)) {
			cd $repo_path
			pwd
		}
		else {
			$git_repo_uri = "https://github.com/$user/$repo.git"
			if ( clone_repo $git_repo_uri $user_path $repo_path) {
				cd $repo_path
				pwd
			}
		}
	}

	function find_local_repo($arg1) {
		$match = @() + ($localrepos | where { $_.repo -eq $arg1 })
		$match += ($localrepos | where { $_.user -eq $arg1 })
		if ( @($match).length -eq 0 ) {
			write-warning ("No repos called `'$arg1`'")
			$localrepos
		}
		elseif ( @($match).length -eq 1 ) {
			$repo_path=$gitdir + "\" + $match[0].user + "\" + $match[0].repo
			cd $repo_path
			pwd
		}
		else {
			write-warning ("Multiple repos match `'$arg1`'")
			return $match
		}
	}


	# Main		

	$localrepos = localrepos

	# 0 args, just show all repos
	if (-not $arg1 -and -not $arg2) {
		return $localrepos
	}
	
	# 1 arg only
	# If it is a github repo, clone it
	# Otherwise search for a local repo with matching USER or REPO name
	if ($arg1 -and -not $arg2) {
		if ($arg1 -match 'https://github.com/(?<username>[^/]*)/(?<reponame>.*).git') {
			$username=$matches['username']
			$reponame=$matches['reponame']
			user_and_repo $username $reponame
		}
        else {
		    find_local_repo $arg1
        }
	}

	# 2 args: clone from github if necessary, then cd to $gitdir/arg1/arg2
	if ($arg1 -and $arg2) {
		user_and_repo $arg1 $arg2
	}
}

export-modulemember -function get-githubrepo -alias gh