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
CaseLevel         CONFORMANCE
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        FDB86CD2-F565-43c3-97CA-8DF06E235E89
CaseName        ReadDirectory.Conf2.Case1
CaseCategory    MTFTP4
CaseDescription {This case is to test the EFI_NOT_STARTED conformance of       \
                Mtftp4.ReadDirectory when the EFI MTFTPv4 Protocol driver has  \
                not been started.}
################################################################################

#
# Begin log ...
#
BeginLog

Include MTFTP4/include/Mtftp4.inc.tcl

BeginScope _MTFTP4_READDIRECTORY_CONFORMANCE2_CASE1_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local ENTS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
EFI_MTFTP4_CONFIG_DATA           R_MtftpConfigData

UINT64                           R_BufferSize
UINT64                           R_Buffer(1000)
EFI_MTFTP4_TOKEN                 R_Token
CHAR8                            R_NameOfFile(20)

Mtftp4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mtftp4SBP.CreateChild - Create Child 1"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# check point
#
SetVar R_NameOfFile         "TestFile"

SetVar R_Token.OverrideData 0
SetVar R_Token.ModeStr      0
SetVar R_Token.Filename     &@R_NameOfFile
SetVar R_Token.OptionCount  0
SetVar R_Token.OptionList   0
SetVar R_Token.BufferSize   1000
SetVar R_Token.Buffer       &@R_Buffer

Mtftp4->ReadDirectory {&@R_Token, 1, 1, 1, &@R_Status}

GetAck

set assert [VerifyReturnStatus R_Status $EFI_NOT_STARTED]
RecordAssertion $assert $Mtftp4ReadDirectoryConfAssertionGuid008               \
                "Mtftp4.ReadDirectory - returns EFI_NOT_STARTED when the EFI   \
                 MTFTPv4 Protocol driver has not been started."                \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_STARTED"

Mtftp4ServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mtftp4SBP.DestroyChild - Destroy Child 1"                     \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

EndScope _MTFTP4_READDIRECTORY_CONFORMANCE2_CASE1_

#
# End Log
#
EndLog