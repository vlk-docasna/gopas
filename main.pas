{1. PostKeyEx32 function} 

procedure PostKeyEx32(key: Word; const shift: TShiftState; specialkey: Boolean); 
{************************************************************ 
* Procedure PostKeyEx32 
* blbej koment, kterej se zamerguje
* Parameters: 
*  key    : virtual keycode of the key to send. For printable 
*           keys this is simply the ANSI code (Ord(character)). 
*  shift  : state of the modifier keys. This is a set, so you 
*           can set several of these keys (shift, control, alt, 
*           mouse buttons) in tandem. The TShiftState type is 
*           declared in the Classes Unit. 
*  specialkey: normally this should be False. Set it to True to 
*           specify a key on the numeric keypad, for example. 
* Description: 
*  Uses keybd_event to manufacture a series of key events matching 
*  the passed parameters. The events go to the control with focus. 
*  Note that for characters key is always the upper-case version of 
*  the character. Sending without any modifier keys will result in 
*  a lower-case character, sending it with [ssShift] will result 
*  in an upper-case character! 
************************************************************} 
type 
  TShiftKeyInfo = record 
    shift: Byte; 
    vkey: Byte; 
  end; 
  byteset = set of 0..7; 
const 
  shiftkeys: array [1..3] of TShiftKeyInfo = 
    ((shift: Ord(ssCtrl); vkey: VK_CONTROL), 
    (shift: Ord(ssShift); vkey: VK_SHIFT), 
    (shift: Ord(ssAlt); vkey: VK_MENU)); 
var 
  flag: integer //DWORD; 
  bShift: ByteSet absolute shift; 
  i: Integer; 
begin 
  for i := 1 to 3 do 
  begin 
    if shiftkeys[i].shift in bShift then 
      keybd_event(shiftkeys[i].vkey, MapVirtualKey(shiftkeys[i].vkey, 0), 0, 0); 
  end; { For } 
  if specialkey then 
    flag := 2 
  else 
    flag := 0; 
  keybd_event(key, MapvirtualKey(key, 0), flag, 0); 
  flag := flag or KEYEVENTF_KEYUP; 
  keybd_event(key, MapvirtualKey(key, 0), flag, 0); 
  for i := 3 downto 1 do 
  begin 
    if shiftkeys[i].shift in bShift then 
      keybd_event(shiftkeys[i].vkey, MapVirtualKey(shiftkeys[i].vkey, 0), 
        KEYEVENTF_KEYUP, 0); 
  end; { For } 
end; { PostKeyEx32 } 

procedure TForm1.Button1Click(Sender: TObject); 
begin 
  PostKeyEx32(VK_LWIN, [], False); 
  PostKeyEx32(Ord('D'), [], False); 
  PostKeyEx32(Ord('C'), [ssctrl, ssAlt], False); 
end; 
{************************************************************} 
{2. With keybd_event API} 

procedure TForm1.Button1Click(Sender: TObject); 
begin 
  {or you can also try this simple example to send any 
   amount of keystrokes at the same time. } 
  {Pressing the A Key and showing it in the Edit1.Text} 
  Edit1.SetFocus; 
  keybd_event(VK_SHIFT, 0, 0, 0); 
  keybd_event(Ord('A'), 0, 0, 0); 
  keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0); 
  {Presses the Left Window Key and starts the Run} 
  keybd_event(VK_LWIN, 0, 0, 0); 
  keybd_event(Ord('R'), 0, 0, 0); 
  keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0); 
end; 
{***********************************************************} 
{3. With keybd_event API} 

procedure PostKeyExHWND(hWindow: HWnd; key: Word; const shift: TShiftState; 
  specialkey: Boolean); 
{************************************************************ 
 * Procedure PostKeyEx 
 * 
 * Parameters: 
 *  hWindow: target window to be send the keystroke 
 *  key    : virtual keycode of the key to send. For printable 
 *           keys this is simply the ANSI code (Ord(character)). 
 *  shift  : state of the modifier keys. This is a set, so you 
 *           can set several of these keys (shift, control, alt, 
 *           mouse buttons) in tandem. The TShiftState type is 
 *           declared in the Classes Unit. 
 *  specialkey: normally this should be False. Set it to True to 
 *           specify a key on the numeric keypad, for example. 
 *           If this parameter is true, bit 24 of the lparam for 
 *           the posted WM_KEY* messages will be set. 
 * Description: 
 *  This 
procedure sets up Windows key state array to correctly 
 *  reflect the requested pattern of modifier keys and then posts 
 *  a WM_KEYDOWN/WM_KEYUP message pair to the target window. Then 
 *  Application.ProcessMessages is called to process the messages 
 *  before the keyboard state is restored. 
 * Error Conditions: 
 *  May fail due to lack of memory for the two key state buffers. 
 *  Will raise an exception in this case. 
 * NOTE: 
 *  Setting the keyboard state will not work across applications 
 *  running in different memory spaces on Win32 unless AttachThreadInput 
 *  is used to connect to the target thread first. 
 *Created: 02/21/96 16:39:00 by P. Below 
 ************************************************************} 
type 
  TBuffers = array [0..1] of TKeyboardState; 
var 
  pKeyBuffers: ^TBuffers; 
  lParam: LongInt; 
begin 
  (* check if the target window exists *) 
  if IsWindow(hWindow) then 
  begin 
    (* set local variables to default values *) 
    pKeyBuffers := nil; 
    lParam := MakeLong(0, MapVirtualKey(key, 0)); 
    (* modify lparam if special key requested *) 
    if specialkey then 
      lParam := lParam or $1000000; 
    (* allocate space for the key state buffers *) 
    New(pKeyBuffers); 
    try 
      (* Fill buffer 1 with current state so we can later restore it. 
         Null out buffer 0 to get a "no key pressed" state. *) 
      GetKeyboardState(pKeyBuffers^[1]); 
      FillChar(pKeyBuffers^[0], SizeOf(TKeyboardState), 0); 
      (* set the requested modifier keys to "down" state in the buffer*) 
      if ssShift in shift then 
        pKeyBuffers^[0][VK_SHIFT] := $80; 
      if ssAlt in shift then 
      begin 
        (* Alt needs special treatment since a bit in lparam needs also be set *) 
        pKeyBuffers^[0][VK_MENU] := $80; 
        lParam := lParam or $20000000; 
      end; 
      if ssCtrl in shift then 
        pKeyBuffers^[0][VK_CONTROL] := $80; 
      if ssLeft in shift then 
        pKeyBuffers^[0][VK_LBUTTON] := $80; 
      if ssRight in shift then 
        pKeyBuffers^[0][VK_RBUTTON] := $80; 
      if ssMiddle in shift then 
        pKeyBuffers^[0][VK_MBUTTON] := $80; 
      (* make out new key state array the active key state map *) 
      SetKeyboardState(pKeyBuffers^[0]); 
      (* post the key messages *) 
      if ssAlt in Shift then 
      begin 
        PostMessage(hWindow, WM_SYSKEYDOWN, key, lParam); 
        PostMessage(hWindow, WM_SYSKEYUP, key, lParam or $C0000000); 
      end 
      else 
      begin 
        PostMessage(hWindow, WM_KEYDOWN, key, lParam); 
        PostMessage(hWindow, WM_KEYUP, key, lParam or $C0000000); 
      end; 
      (* process the messages *) 
      Application.ProcessMessages; 
      (* restore the old key state map *) 
      SetKeyboardState(pKeyBuffers^[1]); 
    finally 
      (* free the memory for the key state buffers *) 
      if pKeyBuffers <> nil then 
        Dispose(pKeyBuffers); 
    end; { If } 
  end; 
end; { PostKeyEx } 

procedure TForm1.Button1Click(Sender: TObject); 
var 
  targetWnd: HWND; 
begin 
  targetWnd := FindWindow('notepad', nil) 
    if targetWnd <> 0 then 
    begin 
      PostKeyExHWND(targetWnd, Ord('I'), [ssAlt], False); 
  end; 
end; 
{***********************************************************} 
{3. With SendInput API} 

procedure TForm1.Button1Click(Sender: TObject); 
const 
   Str: string = 'writing writing writing'; 
var 
  Inp: TInput; 
  I: Integer; 
begin 
  Edit1.SetFocus; 
  for I := 1 to Length(Str) do 
  begin 
    Inp.Itype := INPUT_KEYBOARD; 
    Inp.ki.wVk := Ord(UpCase(Str[i])); 
    Inp.ki.dwFlags := 0; 
    SendInput(1, Inp, SizeOf(Inp)); 
    Inp.Itype := INPUT_KEYBOARD; 
    Inp.ki.wVk := Ord(UpCase(Str[i])); 
    Inp.ki.dwFlags := KEYEVENTF_KEYUP; 
    SendInput(1, Inp, SizeOf(Inp)); 
    Application.ProcessMessages; 
    Sleep(80); 
  end; 
end; 

procedure SendAltTab; 
var 
  KeyInputs: array of TInput; 
  KeyInputCount: Integer; 
  
procedure KeybdInput(VKey: Byte; Flags: DWORD); 
  begin 
    Inc(KeyInputCount); 
    SetLength(KeyInputs, KeyInputCount); 
    KeyInputs[KeyInputCount - 1].Itype := INPUT_KEYBOARD; 
    with  KeyInputs[KeyInputCount - 1].ki do 
    begin 
      wVk := VKey; 
      wScan := MapVirtualKey(wVk, 0); 
      dwFlags := KEYEVENTF_EXTENDEDKEY; 
      dwFlags := Flags or dwFlags; 
      time := 0; 
      dwExtraInfo := 0; 
    end; 
  end; 
begin 
  KeybdInput(VK_MENU, 0);                // Alt 
  KeybdInput(VK_TAB, 0);                 // Tab 
  KeybdInput(VK_TAB, KEYEVENTF_KEYUP);   // Tab 
  KeybdInput(VK_MENU, KEYEVENTF_KEYUP); // Alt 
  SendInput(KeyInputCount, KeyInputs[0], SizeOf(KeyInputs[0])); 
end; 

