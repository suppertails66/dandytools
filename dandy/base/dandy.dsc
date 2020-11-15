
//============================================================
// Remote Control Dandy translation disc build script
//============================================================

IsoPrimaryVolumeDescriptor pDesc
pDesc.systemIdentifier            = "PLAYSTATION"
pDesc.volumeIdentifier            = "DANDY"
pDesc.volumeSetIdentifier         = ""
pDesc.publisherIdentifier         = "HUMAN CORP."
pDesc.dataPreparerIdentifier      = ""
pDesc.applicationIdentifier       = "PLAYSTATION"
pDesc.copyrightFileIdentifier     = "HUMAN_CORP."
pDesc.abstractFileIdentifier      = ""
pDesc.bibliographicFileIdentifier = ""
pDesc.volumeCreationTime          = "1999061721300000\0"
pDesc.volumeModificationTime      = "0000000000000000\0"
pDesc.volumeExpirationTime        = "0000000000000000\0"
pDesc.volumeEffectiveTime         = "0000000000000000\0"

IsoDescriptorSetTerminator descTerminator

IsoFilesystem isoFs
isoFs.setFormat("CDXA")
//isoFs.setSystemArea("base/sysarea.bin")
isoFs.setRawSectorSystemArea("base/sysarea_raw.bin")
isoFs.importDirectoryListing("out/files")

isoFs.insertDiscPointer("CD1.DA", ":track2start", ":track2end")
isoFs.getListedFile("CD1.DA").xa_flags_isCdda = 1
isoFs.insertDiscPointer("CD2.DA", ":track3start", ":track3end")
isoFs.getListedFile("CD2.DA").xa_flags_isCdda = 1
isoFs.insertDiscPointer("CD3.DA", ":track4start", ":track4end")
isoFs.getListedFile("CD3.DA").xa_flags_isCdda = 1
isoFs.insertDiscPointer("CD4.DA", ":track5start", ":track5end")
isoFs.getListedFile("CD4.DA").xa_flags_isCdda = 1

isoFs.importRawSectorFile("discfiles_raw/MUSIC.XAP",
                          "MUSIC.XAP")
isoFs.getListedFile("MUSIC.XAP").setXaSubmodeType("AUDIO")
isoFs.getListedFile("MUSIC.XAP").xa_flags_isInterleaved = 1
isoFs.getListedFile("MUSIC.XAP").xa_fileNumber = 1

isoFs.importRawSectorFile("discfiles_raw/OPENING.STR",
                          "OPENING.STR")
isoFs.getListedFile("OPENING.STR").setXaSubmodeType("DATA")
isoFs.getListedFile("OPENING.STR").xa_flags_isInterleaved = 1
isoFs.getListedFile("OPENING.STR").xa_fileNumber = 1

isoFs.importRawSectorFile("discfiles_raw/VOICE.XAP",
                          "VOICE.XAP")
isoFs.getListedFile("VOICE.XAP").setXaSubmodeType("AUDIO")
isoFs.getListedFile("VOICE.XAP").xa_flags_isInterleaved = 1
isoFs.getListedFile("VOICE.XAP").xa_fileNumber = 1

isoFs.getListedFile("ADV.PAC").xa_flags_isMode2 = 1
isoFs.getListedFile("ADV.STM").xa_flags_isMode2 = 1
isoFs.getListedFile("GAME.XM").xa_flags_isMode2 = 1
isoFs.getListedFile("SINKOU.PAC").xa_flags_isMode2 = 1
isoFs.getListedFile("SINKOU.S3M").xa_flags_isMode2 = 1
isoFs.getListedFile("SLPS_022.43").xa_flags_isMode2 = 1
isoFs.getListedFile("SONIC.AOE").xa_flags_isMode2 = 1
isoFs.getListedFile("SYSTEM.CNF").xa_flags_isMode2 = 1

isoFs.addPrimaryVolumeDescriptor(pDesc)
isoFs.addDescriptorSetTerminator()
isoFs.addTypeLPathTable()
isoFs.addTypeLPathTableCopy()
isoFs.addTypeMPathTable()
isoFs.addTypeMPathTableCopy()
  isoFs.addDirectoryDescriptor("")
    isoFs.addListedFile("SYSTEM.CNF")
    isoFs.addListedFile("SLPS_022.43")
    isoFs.addListedFile("SINKOU.S3M")
    isoFs.addListedFile("SINKOU.PAC")
    isoFs.addListedFile("ADV.STM")
    isoFs.addListedFile("ADV.PAC")
    isoFs.addListedFile("GAME.XM")
    isoFs.addListedFile("SONIC.AOE")
    isoFs.addListedFile("VOICE.XAP")
    isoFs.addListedFile("MUSIC.XAP")
    isoFs.addListedFile("OPENING.STR")

CdImage cd
  cd.addTrackStart(1, "MODE2FORM2")
    cd.addModeChange("MODE2FORM1")
    cd.addTrackIndex(1)
    cd.addIsoFilesystem(isoFs)
    cd.addEmptySectors(150)
  cd.addTrackEnd()
  
  cd.addTrackStart(2, "AUDIO")
    cd.addPregapMsf(0, 2, 0)
    cd.addLabel(":track2start")
//      cd.addRawData("dandy_02.bin")
      cd.addRawDataWithSkippedInitialSectors("discaudiotracks/dandy_02.bin", 150)
    cd.addLabel(":track2end")
  cd.addTrackEnd()
    
  cd.addTrackStart(3, "AUDIO")
    cd.addPregapMsf(0, 2, 0)
    cd.addLabel(":track3start")
//      cd.addRawData("dandy_03.bin")
      cd.addRawDataWithSkippedInitialSectors("discaudiotracks/dandy_03.bin", 150)
    cd.addLabel(":track3end")
  cd.addTrackEnd()
    
  cd.addTrackStart(4, "AUDIO")
    cd.addPregapMsf(0, 2, 0)
    cd.addLabel(":track4start")
//      cd.addRawData("dandy_04.bin")
      cd.addRawDataWithSkippedInitialSectors("discaudiotracks/dandy_04.bin", 150)
    cd.addLabel(":track4end")
  cd.addTrackEnd()
    
  cd.addTrackStart(5, "AUDIO")
    cd.addPregapMsf(0, 2, 0)
    cd.addLabel(":track5start")
//      cd.addRawData("dandy_05.bin")
      cd.addRawDataWithSkippedInitialSectors("discaudiotracks/dandy_05.bin", 150)
    cd.addLabel(":track5end")
  cd.addTrackEnd()

// DEBUG
//cd.disableEccCalculation = 1

cd.exportBinCue("dandy_build")
