function Get-GithubRepo {
	[CmdLetBinding()]
	Param(
		[string]$Search
	)

	
function Find-Dev {
    $Locations = 'C:\Jesse\dev','D:\dev','C:\Scratch\drees\git'
    $i = 0
    While ((Test-Path -Path $Locations[$i]) -eq $False){
        $i++
    }
    $Locations[$i]
}


	$gitdir = (Find-Dev)

	function Get-LocalRepos {
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

	function Get-GitRepoByUserAndRepo{
        [CmdLetBinding()]
        Param(
            [Parameter(Mandatory=$True)]$UserName,
            [Parameter(Mandatory=$True)]$RepoName
        )
		$user_path=$gitdir + "\" + $UserName
		$repo_path=$user_path + "\" + $RepoName
        Write-Verbose "Calculated local repo path is $repo_path"

		if (Test-Path($repo_path)) {
			cd $repo_path
			pwd
		}
		else {
			$git_repo_uri = "https://github.com/$username/$reponame.git"
			if ( clone_repo $git_repo_uri $user_path $repo_path) {
				cd $repo_path
				pwd
			}
		}
	}

	function Find-LocalRepo($SearchString) {
		$match = @() + ($localrepos | where { $_.repo -eq $SearchString })
		$match += ($localrepos | where { $_.user -eq $SearchString })
		if ( @($match).length -eq 0 ) {
			write-warning ("No repos called `'$SearchString`'")
			$localrepos
		}
		elseif ( @($match).length -eq 1 ) {
			$repo_path=$gitdir + "\" + $match[0].user + "\" + $match[0].repo
			cd $repo_path
			pwd
		}
		else {
			write-warning ("Multiple repos match `'$SearchString`'")
			return $match
		}
	}


	# Main		

	$localrepos = Get-LocalRepos

	# 0 args, just show all repos
	if (-not $Search) {
		return $localrepos
	}
	
	# 1 arg only
	# If it is a github repo, clone it
	# Otherwise search for a local repo with matching USER or REPO name

	Switch ($Search) {
		{$_ -match '(http(s|)://|)github.com/(?<username>[^/]*)/(?<reponame>.*)'} {
            Write-Verbose "Match found on gh url"
		    $Search -match '(http(s|)://|)github.com/(?<username>[^/]*)/(?<reponame>.*)' | Out-Null

			$UserName=$matches['username']
			$RepoName=$matches['reponame']
            Write-Verbose "User: $UserName, Repo: $RepoName"
		}
        {$_ -match ','} {
            Write-Verbose "Match found on ,"
            $strSplit = $Search -split ','
            $UserName = $strSplit[0]
            $RepoName = $strSplit[1]
        }
        Default {
		    Find-LocalRepo -SearchString $Search 
        }
    }
    if ($UserName -and $RepoName) {
        Get-GitRepoByUserAndRepo -UserName $UserName -RepoName $RepoName
    }
}
set-alias gh get-githubrepo
export-modulemember -function get-githubrepo -alias gh