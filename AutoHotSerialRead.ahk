;	https://github.com/UsernamePlankalkul/
;	AutoHotSerialRead (RX)
;	This script does a MsgBox for each line received from a serial port (COM) .
;	Very usefull for serial communication with Microcontrollers like Arduino , ESP (Espressif) , Raspberry PI and ...
;	For sending Data to Microcontrollers , use AutoHotSerialWrite (TX).


#Requires AutoHotkey v2.0

GENERIC_READ := 0x80000000
GENERIC_WRITE := 0x40000000
OPEN_EXISTING := 3
FILE_ATTRIBUTE_NORMAL := 0x80
PORT := "COM3"
BAUD_RATE := "115200"

; Open COM port
hPort := DllCall("CreateFile", "Str", "\\.\" PORT, "UInt", GENERIC_READ | GENERIC_WRITE, 
                 "UInt", 0, "Ptr", 0, "UInt", OPEN_EXISTING, "UInt", FILE_ATTRIBUTE_NORMAL, "Ptr", 0, "Ptr")

if (hPort = -1) {
    MsgBox "Failed to open " PORT ". Possible reasons:`n- Port doesn't exist`n- Port in use`n- Wrong port number`nCheck Device Manager.", "Error"
    ExitApp
}

; Setting UP COM port Parameters
dcb := Buffer(92, 0)  ; DCB structure size is 92 bytes
DllCall("GetCommState", "Ptr", hPort, "Ptr", dcb.Ptr)
NumPut("UInt", 92, dcb, 0)    ; DCB length
NumPut("UInt", BAUD_RATE, dcb, 4) ; Baud rate
NumPut("UChar", 8, dcb, 12)   ; Byte size (8)
NumPut("UChar", 0, dcb, 13)   ; Parity (None)
NumPut("UChar", 0, dcb, 14)   ; Stop bits (1)
DllCall("SetCommState", "Ptr", hPort, "Ptr", dcb.Ptr)

; Setting UP Timeouts
timeouts := Buffer(20, 0)  ; COMMTIMEOUTS structure size is 20 bytes
NumPut("UInt", 0, timeouts, 0)   ; ReadIntervalTimeout
NumPut("UInt", 0, timeouts, 4)   ; ReadTotalTimeoutMultiplier
NumPut("UInt", 100, timeouts, 8) ; ReadTotalTimeoutConstant
DllCall("SetCommTimeouts", "Ptr", hPort, "Ptr", timeouts.Ptr)

; Creating Read Buffer
readBuf := Buffer(1024, 0)  ; 1KB buffer for reading
bufferPtr := readBuf.Ptr    ; Store pointer
bufferSize := readBuf.Size  ; Store size

; Reading Loop
MsgBox "Connected to " PORT ". Listening for messages...`nPress Esc to exit.", "Info"

while true {
    Sleep 100
    bytesRead := 0
    success := DllCall("ReadFile", "Ptr", hPort, "Ptr", bufferPtr, "UInt", bufferSize, 
                      "UInt*", &bytesRead, "Ptr", 0)
    
    if (success && bytesRead > 0) {
        data := StrGet(bufferPtr, bytesRead, "UTF-8")
        lines := StrSplit(data, "`n")
        for line in lines {
            line := Trim(line, "`r`n")
            if (line != "") {
                MsgBox line, "Microcontroller Message"
            }
        }
    }
}

; Cleanup on exit
OnExit((*) => (DllCall("CloseHandle", "Ptr", hPort)))

; Exit with Esc key
Esc::ExitApp
