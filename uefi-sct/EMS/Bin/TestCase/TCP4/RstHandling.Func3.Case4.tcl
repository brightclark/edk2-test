# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         FUNCTION
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT

#
# test case Name, category, description, GUID...
#
CaseGuid          C459CF8A-8BF1-4a77-BB83-BD817C12DAE6
CaseName          RstHandling.Func3.Case4
CaseCategory      TCP
CaseDescription   {This item is to test the <EUT> correctly validate the rcvd  \
                   RST segment while in ESTABLISHED state. RST is valid if     \
                   the sequence number of RST segment is in the window.}
################################################################################
Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironmentBegin {} {
global RST

  UpdateTcpSendBuffer TCB -c $RST
  SendTcpPacket TCB

  DestroyTcb
  DestroyPacket
  DelEntryInArpCache

  Tcp4ServiceBinding->DestroyChild "@R_Tcp4Handle, &@R_Status"
  GetAck
 
}

proc CleanUpEutEnvironmentEnd {} {
  EndLogPacket
  EndScope _TCP4_RSTHANDLING_FUNC3_CASE4_
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope on OS.
#
BeginScope _TCP4_RSTHANDLING_FUNC3_CASE4_

BeginLogPacket RstHandling.Func3.Case4 "host $DEF_EUT_IP_ADDR and host         \
                                             $DEF_ENTS_IP_ADDR"

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Tcp4Handle
UINTN                            R_Context

EFI_TCP4_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP4_CONFIG_DATA             R_Configure_Tcp4ConfigData

EFI_TCP4_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP4_CONNECTION_TOKEN        R_Connect_ConnectionToken

EFI_TCP4_COMPLETION_TOKEN        R_Close_CompletionToken
EFI_TCP4_CLOSE_TOKEN             R_Close_CloseToken

INTN                             R_Connection_State

LocalEther  $DEF_ENTS_MAC_ADDR
RemoteEther $DEF_EUT_MAC_ADDR
LocalIp     $DEF_ENTS_IP_ADDR
RemoteIp    $DEF_EUT_IP_ADDR

#
# Initialization of TCB related on OS side.
#
set L_Port $DEF_ENTS_PRT
set R_Port $DEF_EUT_PRT

CreateTcb TCB $DEF_ENTS_IP_ADDR $L_Port $DEF_EUT_IP_ADDR $R_Port
CreatePayload HelloWorld STRING 11 HelloWorld

#
# Add an entry in ARP cache.
#
AddEntryInArpCache

#
# Create Tcp4 Child.
#
Tcp4ServiceBinding->CreateChild "&@R_Tcp4Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Tcp4Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4SBP.CreateChild - Create Child 1."                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Configure TCP instance.
#
SetVar R_Configure_AccessPoint.UseDefaultAddress      FALSE
SetIpv4Address R_Configure_AccessPoint.StationAddress $DEF_EUT_IP_ADDR
SetIpv4Address R_Configure_AccessPoint.SubnetMask     $DEF_EUT_MASK
SetVar R_Configure_AccessPoint.StationPort            $R_Port
SetIpv4Address R_Configure_AccessPoint.RemoteAddress  $DEF_ENTS_IP_ADDR
SetVar R_Configure_AccessPoint.RemotePort             $L_Port
SetVar R_Configure_AccessPoint.ActiveFlag             TRUE

SetVar R_Configure_Tcp4ConfigData.TypeOfService       0
SetVar R_Configure_Tcp4ConfigData.TimeToLive          128
SetVar R_Configure_Tcp4ConfigData.AccessPoint         @R_Configure_AccessPoint
SetVar R_Configure_Tcp4ConfigData.ControlOption       0

Tcp4->Configure {&@R_Configure_Tcp4ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Configure - Configure Child 1."                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Call Tcp4->Connect to initialize connection
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Connect_ConnectionToken.CompletionToken @R_Connect_CompletionToken
Tcp4->Connect {&@R_Connect_ConnectionToken, &@R_Status}
GetAck
if { $R_Status == $EFI_SUCCESS } {
  set assert pass
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Tcp4.Connect - Open an active connection."                  \
                  "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Tcp4.Connect - Open an active connection."                  \
                  "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

# Handle three-way handshake
# <EUT> --> <OS>: SYN
ReceiveTcpPacket TCB 5
if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_syn} != 1} {
    set assert fail
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "Active Conn Setup: EUT doesn't send out SYN."

    CleanUpEutEnvironmentBegin
    BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
    GetAck
    CleanUpEutEnvironmentEnd
    return
  }
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Active Conn Setup: EUT doesn't send out packet."

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

# <OS> --> <EUT>: SYN|ACK
set L_TcpFlag [expr $SYN|$ACK]
UpdateTcpSendBuffer TCB -c $L_TcpFlag
SendTcpPacket TCB

# <EUT> --> <OS>: ACK
ReceiveTcpPacket TCB 5
if { ${TCB.received}!=1 || ${TCB.r_f_ack}!=1 } {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Active Conn Setup: EUT doesn't sent out ACK"

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}


#
# BUGBUG, Call GetModeData will result in Crash
Tcp4->GetModeData {&@R_Connection_State, NULL, NULL, NULL, NULL, &@R_Status}
GetAck
GetVar R_Connection_State
if { $R_Connection_State != $Tcp4StateEstablished || $R_Status != $EFI_SUCCESS} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Tcp4 - GetModeData."                                        \
                  "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"    \
                  "CurState - $R_Connection_State, ExpectState - $Tcp4StateEstablished"

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}
RecordMessage DEFAULT "Enter ESTABLISHED state"

#
# Instruct <OS> send a invalid RST segment, RST.ack doesn't ack the SYN
#
set OrigSeq ${TCB.r_acked_seq}
set Expect_Seq [expr ${TCB.l_isn} + ${TCB.r_win} -1]
set L_TcpFlag [expr $RST|$ACK]
UpdateTcpSendBuffer TCB -c $L_TcpFlag -s $Expect_Seq
 
SendTcpPacket TCB

#
# Expect: Nothing, Connection still in ESTABLISHED state
#
Tcp4->GetModeData {&@R_Connection_State, NULL, NULL, NULL, NULL, &@R_Status}
GetAck
GetVar R_Connection_State
if { $R_Connection_State != $Tcp4StateClosed || $R_Status != $EFI_SUCCESS} {
  set assert fail
  RecordAssertion $assert $Tcp4RstHandlingFunc3AssertionGuid004                \
                  "Tcp4 - GetModeData."                                        \
                  "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"    \
                  "CurState - $R_Connection_State, ExpectState - $Tcp4StateClosed"

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}
RecordAssertion pass $GenericAssertionGuid                                     \
                "<ESTABLISHED>: On recv invalid RST, remain in ESTABLISHED"

set  TCB.r_acked_seq $OrigSeq

# OS --> EUT: SYNC
# Expect: EUT --> OS: SYNC_ACK
set L_TcpFlag [expr $URG|$ACK]
UpdateTcpSendBuffer TCB -c $L_TcpFlag -p HelloWorld
SendTcpPacket TCB

ReceiveTcpPacket TCB 5
if { ${TCB.received}!=1 } {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "<ESTABLISHED>: On recv invalid RST, remain in ESTABLISHED"  \
                  "can't respond to DATA correctly"

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

RecordAssertion pass $GenericAssertionGuid                                     \
                "<ESTABLISHED>: On recv invalid RST, remain in ESTABLISHED"    \
                "respond to DATA correctly"

CleanUpEutEnvironmentBegin
BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
CleanUpEutEnvironmentEnd
