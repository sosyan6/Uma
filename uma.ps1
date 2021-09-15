# ������
# Win32Api�錾
Add-Type -MemberDefinition @'
public struct RECT
{
    public int left;
    public int top;
    public int right;
    public int bottom;
}

[DllImport("user32.dll")]
public static extern bool GetWindowRect( IntPtr hwnd, out RECT lp );

[DllImport("user32.dll", SetLastError = true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint flags);
'@ -NameSpace $null -Name win32

#�ϐ���
$ProgressPreference = "SilentlyContinue"
( $init = {
	Set-Location "$home/Umamusume"
	Add-Type -AssemblyName System.Windows.Forms

	$script:n = [System.Environment]::NewLine;
	$script:verUri = "https://api.github.com/repos/amate/UmaUmaCruise/releases?per_page=1&page=1"
	$script:libUri = "https://raw.githubusercontent.com/amate/UmaUmaCruise/master/UmaLibrary/UmaMusumeLibrary_v2.json"
	$script:umaLibPath = "./UmaUmaCruise/UmaLibrary/UmaMusumeLibrary.json"
} ).Invoke()
$wait = 100

if( !( Test-Path -Path "./bounds.json" ) ){
	Set-Content -Path "./bounds.json" -Encoding UTF8 -Value @'
{
	"vertical": {
		"x": 1344,
		"y": 0,
		"w": 584,
		"h": 1048
	},
	"horizontal": {
		"x": 61,
		"y": 0,
		"w": 1810,
		"h": 1048
	}
}
'@
}
$bounds = Get-Content -Path "./bounds.json" | ConvertFrom-Json

# �A�v���N��
if( ![System.Diagnostics.Process]::GetProcessesByName( "umamusume" ) ){
	Start-Process "dmmgameplayer://umamusume/cl/general/umamusume"
	Write-Host "DMM�v���C���[��umamusume���N�����܂���"
}else{
	Write-Host -ForegroundColor Yellow "umamusume�͊��ɊJ����Ă��܂�"
}
if( ![System.Diagnostics.Process]::GetProcessesByName( "UmaUmaCruise" ) ){
	Start-Process "./UmaUmaCruise/UmaUmaCruise.exe"
	Write-Host "UmaUmaCruise���N�����܂���"
}else{
	Write-Host -ForegroundColor Yellow "UmaUmaCruise�͊��ɊJ����Ă��܂�"
}

Write-Host "UmaUmaCruise�̍X�V���m�F���Ă��܂�..."

$version = ( Invoke-WebRequest -Uri $verUri ).Content | ConvertFrom-Json
( Get-Content -Encoding UTF8 -Raw -Path "./UmaUmaCruise/readme.md" ) -match "v\d+\.\d+" | Out-Null
if( $version.name -eq $Matches[0] ){
	Write-Host -ForegroundColor Cyan "���݂�UmaUmaCrise�͍ŐV�o�[�W�����ł�"
	Write-Host "UmaMusumeLibrary�̍X�V���m�F���Ă��܂�..."
	if( ( Get-Item -Path $umaLibPath ).Length -eq ( Invoke-WebRequest -Method HEAD -Uri $libUri ).Headers["Content-Length"] ){
		Write-Host -ForegroundColor Cyan "UmaMusumeLibrary�̍X�V�͂���܂���"
	}else{
		Write-Host -ForegroundColor Red "UmaMusumeLibrary�̍X�V������܂�"
		Start-Job -InitializationScript $init -ScriptBlock {
			Rename-Item -Path $umaLibPath -NewName "UmaMusumeLibrary_prev.json" -Force
			Invoke-WebRequest -Uri $libUri -OutFile $umaLibPath

			[System.Windows.Forms.MessageBox]::Show(
				"UmaMusumeLibrary���X�V���܂���",
				"�X�V����",
				[System.Windows.Forms.MessageBoxButtons]::OK,
				[System.Windows.Forms.MessageBoxIcon]::Information
			)
		} | Out-Null
	}
}else{
	Write-Host -ForegroundColor Red "UmaUmaCruise�̍ŐV�o�[�W����������܂�($( $Matches[0] ) -> $( $version.name ))"
	$script:DLUUC = Start-Job -InitializationScript $init -ArgumentList $version -ScriptBlock {
		param( $version )

		Invoke-WebRequest -Uri $version.assets.browser_download_url -OutFile "./uuc.tmp.zip"
		Expand-Archive -Path "./uuc.tmp.zip"
	}
}

# �ҋ@
Write-Host "�E�}���̋N����ҋ@���Ă��܂�..."
While( ![System.Diagnostics.Process]::GetProcessesByName( "umamusume" ).MainWindowHandle )
{
	Start-Sleep -m $wait
}
# �N��
$ps = [System.Diagnostics.Process]::GetProcessesByName( "umamusume" )
$rect = New-Object -TypeName "win32+RECT"

Write-Host "�E�}���̃E�B���h�E�T�C�Y���Œ肵�܂�..."
While( [System.Diagnostics.Process]::GetProcessesByName( "umamusume" ).MainWindowHandle )
{
	Start-Sleep -m $wait

	[win32]::GetWindowRect( $ps.MainWindowHandle, [ref]$rect ) | Out-Null
	if( ( $rect.right - $rect.left ) / ( $rect.bottom - $rect.top + 1 ) -lt 1 ){
		$bound = $bounds.vertical
	}else{
		$bound = $bounds.horizontal
	}

	if( [System.Windows.Forms.Control]::IsKeyLocked( [System.Windows.Forms.Keys]::Scroll ) ){
		if( $bound.x -ne $rect.left -or
			$bound.y -ne $rect.top -or
			$bound.w -ne ( $rect.right - $rect.left ) -or
			$bound.h -ne ( $rect.bottom - $rect.top )
		){
			$bound.x = $rect.left
			$bound.y = $rect.top
			$bound.w = ( $rect.right - $rect.left )
			$bound.h = ( $rect.bottom - $rect.top )
			Write-Host $bound
			ConvertTo-Json -InputObject $bounds | Set-Content -Path "./bounds.json" -Encoding UTF8
		}
	}else{
		[win32]::SetWindowPos( $ps.MainWindowHandle, [IntPtr]::Zero, $bound.x, $bound.y, $bound.w, $bound.h, 0 ) | Out-Null
	}
}

# �I��
Stop-Process -Name "UmaUmaCruise"

if( $DLUUC ){
	if( [System.Windows.Forms.MessageBox]::Show(
		"UmaUmaCruise�̍X�V�̏������ł��܂����B${n}�X�V���܂����H",
		"�X�V�̊m�F",
		[System.Windows.Forms.MessageBoxButtons]::YesNo,
		[System.Windows.Forms.MessageBoxIcon]::Question
	) -and ( $DLUUC | Wait-Job ) ){
		Remove-Item "./UmaUmaCruise.old" -Force
		Rename-Item -Path "./UmaUmaCruise" -NewName "./UmaUmaCruise.old" -Force
		Move-Item -Path "./uuc.tmp/UmaUmaCruise" -Destination "./"
		Copy-Item -Path "./UmaUmaCruise.old/screenshot" -Destination "./UmaUmaCruise/" -Recurse -Force
		Copy-Item -Path "./UmaUmaCruise.old/*.json" -Destination "./UmaUmaCruise/" -Force

		[System.Windows.Forms.MessageBox]::Show( "UmaUmaCruise�̍X�V���������܂���" )
	}
	Remove-Item "uuc.tmp*" -Force
}