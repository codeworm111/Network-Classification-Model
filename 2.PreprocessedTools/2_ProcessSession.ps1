$SESSIONS_COUNT_LIMIT_MIN = 0
$SESSIONS_COUNT_LIMIT_MAX = 6000
$TRIMED_FILE_LEN = 784
$SOURCE_SESSION_DIR = "2_Session\L7"

echo "If Sessions more than $SESSIONS_COUNT_LIMIT_MAX we only select the largest $SESSIONS_COUNT_LIMIT_MAX."
echo "Finally Selected Sessions:"

$dirs = gci $SOURCE_SESSION_DIR -Directory
foreach($d in $dirs)
{
    $files = gci $d.FullName
    $count = $files.count
    if($count -gt $SESSIONS_COUNT_LIMIT_MIN)
    {             
        echo "$($d.Name) $count"        
        if($count -gt $SESSIONS_COUNT_LIMIT_MAX)
        {
            $files = $files | sort Length -Descending | select -First $SESSIONS_COUNT_LIMIT_MAX
            $count = $SESSIONS_COUNT_LIMIT_MAX
        }

        $files = $files | resolve-path
        # Ignore the .pcap file that has less than 10 packets
        $test  = $files | get-random -count ([int]($count/10))
        $train = $files | ?{$_ -notin $test}     

        $path_test  = "3_ProcessedSession\FilteredSession\Test\$($d.Name)"
        $path_train = "3_ProcessedSession\FilteredSession\Train\$($d.Name)"
        ni -Path $path_test -ItemType Directory -Force
        ni -Path $path_train -ItemType Directory -Force    

        cp $test -destination $path_test        
        cp $train -destination $path_train
    }
}

echo "All files will be trimed to $TRIMED_FILE_LEN length and if it's even shorter we'll fill the end with 0x00..."

$paths = @(('3_ProcessedSession\FilteredSession\Train', '3_ProcessedSession\TrimedSession\Train'), ('3_ProcessedSession\FilteredSession\Test', '3_ProcessedSession\TrimedSession\Test'))
foreach($p in $paths)
{
    foreach ($d in gci $p[0] -Directory) 
    {
        ni -Path "$($p[1])\$($d.Name)" -ItemType Directory -Force
        foreach($f in gci $d.fullname)
        {
            $content = [System.IO.File]::ReadAllBytes($f.FullName)
            $len = $f.length - $TRIMED_FILE_LEN
            if($len -gt 0)
            {        
                $content = $content[0..($TRIMED_FILE_LEN-1)]        
            }
            elseif($len -lt 0)
            {        
                $padding = [Byte[]] (,0x00 * ([math]::abs($len)))
                $content = $content += $padding
            }
            Set-Content -value $content -encoding byte -path "$($p[1])\$($d.Name)\$($f.Name)"
        }        
    }
}
