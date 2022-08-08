Attribute VB_Name = "schaduwRendementen"
Sub schaduwRendementenGenerateScenarios()


'
'   set up scenarios voor het berekenen vd schaduw rendementen
'   schaduw rendement = rendement waar boven er allocatie naar een asset class plaatsvind
'
'

Dim rendementMin As Double
Dim rendementMax As Double
Dim noSteps As Integer
Dim stepSize As Double

Dim noAssets As Integer
Dim selectedAsset As Integer


Dim i As Integer, j As Integer

'Sla gebruikte instelling op

Application.ScreenUpdating = False


'Schrijf parameters naar Matlab
'IR analyse

'Input voor optimalisatie
tab0 = "Absolute visies"
tab1 = "Optimalisatie"
tab2 = "Restricties"
tab3 = "Scenarios"
tab4 = "schaduw rendementen"



Worksheets(tab4).Activate


With Worksheets(tab4)



'
'   verwijder oude resultaten
'

i = 0
j = 0


While (.Range("scenariosSchadusRendementen").Offset(i, j).Value <> "") Or (.Range("scenariosSchadusRendementen").Offset(i + 1, j).Value <> "")

    While (.Range("scenariosSchadusRendementen").Offset(i, j).Value <> "") Or (.Range("scenariosSchadusRendementen").Offset(i + 1, j).Value <> "")
    
        .Range("scenariosSchadusRendementen").Offset(i, j).Value = ""
        i = i + 1
    Wend
    j = j + 1
    i = 0
Wend



rendementMin = .Range("schaduwRendMin").Value
rendementMax = .Range("schaduwRendMax").Value

noSteps = .Range("schaduwRendNoSteps").Value
If (rendementMax <= rendementMin) Then
    MsgBox ("max rendement moet groter zijn dan min")
    Exit Sub
End If

stepSize = (rendementMax - rendementMin) / noSteps

i = 0
selectedAsset = 0

noSteps = .Range("schaduwRendNoSteps").Value

'tel aantal asset classes in portefeuille en lees asset class waarvoor schaduw return bepaald moet worden

While (.Range("schaduwRendAssets").Offset(i + 1, 0).Value <> "")
    If (.Range("schaduwRendAssets").Offset(i + 1, 2).Value = 1) Then
        selectedAsset = i + 1
    End If
    .Range("scenariosSchadusRendementen").Offset(i + 1, 0).Value = .Range("schaduwRendAssets").Offset(i + 1, 0).Value
    i = i + 1
Wend

noAssets = i

.Range("schaduwRendnoAssets").Value = noAssets

If (selectedAsset = 0) Then
    MsgBox ("kies een asset class")
    Exit Sub
End If


'
'   schrijf scenarios in sheet.
'

For i = 1 To noSteps + 1

    .Range("scenariosSchadusRendementen").Offset(0, i).Value = "Schaduw " & i

    For j = 1 To noAssets
    
        If j = selectedAsset Then
        
            .Range("scenariosSchadusRendementen").Offset(j, i).Value = rendementMin + stepSize * (i - 1)
            
        Else
            .Range("scenariosSchadusRendementen").Offset(j, i).Value = .Range("schaduwRendAssets").Offset(j, 1).Value
        End If
        
        
            .Range("scenariosSchadusRendementen").Offset(noAssets + 3 + j, i).ClearContents

    
    
    Next j
Next i




End With

Worksheets("schaduw rendementen").Activate

End Sub

Sub schaduwRendementenOptimalisatie()

Dim noSteps As Integer
Dim stepSize As Double

Dim noAssets As Integer


MLShowMatlabErrors ("yes")

'Leeg geheugen Matlab
MLEValstring ("clear")
MLEValstring ("P1 = path")
MLEValstring ("P2 = '\\fserver11\groups1\IC_modelportfolio\Cluster Portfolio Construction\Modelportefeuille'")
MLEValstring ("cd '\\fserver11\groups1\IC_modelportfolio\Cluster Portfolio Construction\Modelportefeuille'")
MLEValstring ("path(P2,P1)")


'Input voor optimalisatie
tab0 = "Absolute visies"
tab1 = "Optimalisatie"
tab2 = "Restricties"
tab3 = "Scenarios"
tab4 = "schaduw rendementen"

With Worksheets(tab4)

noSteps = .Range("schaduwRendNoSteps").Value
noAssets = .Range("schaduwRendnoAssets").Value

MLPutMatrix "scen_names", Range(.Range("scenariosSchadusRendementen").Offset(0, 1), .Range("scenariosSchadusRendementen").Offset(0, noSteps + 1))
MLPutMatrix "asset_names", Range(.Range("schaduwRendAssets").Offset(1, 0), .Range("schaduwRendAssets").Offset(noAssets, 0))



MLPutMatrix "ScenarioKans1", Worksheets(tab1).Range("B6:H13")

MLEValstring ("ScenarioKans = eye(" & (noSteps + 1) & ")")
MLEValstring ("scenarios =" & (noSteps + 1))                  'aantal scenarios
MLEValstring ("Nassets=" & noAssets)                        'aantal assets

'laat deze nu nog naar de optimalizatie sheet verwijzen:
'gebruik waarden kansgewogen scenario

Dim waardeKansGew As Double


MLPutMatrix "MinRet", Range(Worksheets(tab1).Cells(20, 2), Worksheets(tab1).Cells(27, 2))


MLEValstring ("MinRet(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 2).Value)

MLPutMatrix "MinRet_actief", Range(Worksheets(tab1).Cells(20, 3), Worksheets(tab1).Cells(27, 3))

MLEValstring ("MinRet_actief(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 3).Value)

MLPutMatrix "MaxTE", Range(Worksheets(tab1).Cells(20, 4), Worksheets(tab1).Cells(27, 4))
MLEValstring ("MaxTE(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 4).Value)

MLPutMatrix "MaxTE_actief", Range(Worksheets(tab1).Cells(20, 5), Worksheets(tab1).Cells(27, 5))
MLEValstring ("MaxTE_actief(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 5).Value)

MLPutMatrix "MaxLPM", Range(Worksheets(tab1).Cells(20, 6), Worksheets(tab1).Cells(27, 6))
MLEValstring ("MaxLPM(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 6).Value)

MLPutMatrix "MaxLPM_actief", Range(Worksheets(tab1).Cells(20, 7), Worksheets(tab1).Cells(27, 7))
MLEValstring ("MaxLPM_actief(1:" & (noSteps + 1) & ") =" & Worksheets(tab1).Cells(27, 7).Value)

MLPutMatrix "doelstelling", Range(Worksheets(tab1).Cells(105, 3), Worksheets(tab1).Cells(112, 3))
MLEValstring ("doelstelling = ones(1," & (noSteps + 1) & ")")



'MLPutMatrix "doorrekenen", Range(Worksheets(tab1).Cells(20, 9), Worksheets(tab1).Cells(27, 9))

MLEValstring ("doorrekenen=cell(1," & (noSteps + 1) & ")")      ' alle scenario's doorrekenen..
MLEValstring ("doorrekenen(:)={'Ja'}")

MLEValstring ("show_plot{1}='Ja'")

'MLPutMatrix "show_plot", Worksheets("Control panel").Range("B36")
'
MLPutMatrix "bm_nr", Worksheets(tab1).Range("B126")
'
MLPutMatrix "lpm_target", Worksheets(tab1).Range("B30")
MLPutMatrix "lpm_orde", Worksheets(tab1).Range("B31")
'
MLPutMatrix "Niter", Worksheets(tab1).Range("B34")
MLPutMatrix "Nport", Worksheets(tab1).Range("B35")
'
''Lees visies in -> returns + Standaard deviaties + correlatie
'gebruik evenwichts correlatie / standaard deviaties
Worksheets(tab0).Activate 'absolute visies
For i = 1 To (noSteps + 1)
    Cells(1, 2).Value = i
    MLPutMatrix "visienr", Cells(1, 2)
    
    MLPutMatrix "schaduwRendementen", Range(.Range("scenariosSchadusRendementen").Offset(1, i), .Range("scenariosSchadusRendementen").Offset(noAssets, i))
    MLPutMatrix "schaduwCorr", Range(Worksheets(tab0).Cells(4, 3), Worksheets(tab0).Cells((noAssets + 3), noAssets + 3))
    
    MLEValstring "mat = [schaduwRendementen,schaduwCorr]"
    'MLPutMatrix "mat", Range(Worksheets(tab0).Cells(4 + (i - 1) * (ncat + 3), 2), Worksheets(tab0).Cells(i * (ncat + 3), ncat + 3))
    MLEValstring ("[mu,covm] = VertaalMat(mat)")
    MLEValstring ("pars.meanmat(:,visienr) = mu;")
    MLEValstring ("pars.covmat(:,:,visienr) = covm;")
    MatlabRequest
    Cells(1, 2).ClearContents
Next i

''Lees restricties in
Start = 4
Worksheets(tab2).Activate 'restricties
MLPutMatrix "InPortefeuille", Range(Worksheets(tab2).Cells(107, 2), Worksheets(tab2).Cells(106 + noAssets, 2))
MLPutMatrix "Rest_tot", Range(Worksheets(tab2).Cells(Start, 3), Worksheets(tab2).Cells(Start - 1 + noAssets, 4))
MLPutMatrix "Rest_port", Range(Worksheets(tab2).Cells(Start, 5), Worksheets(tab2).Cells(Start - 1 + noAssets, 6))
MLPutMatrix "w_t0", Range(Worksheets(tab2).Cells(Start, 7), Worksheets(tab2).Cells(Start - 1 + noAssets, 7))
MLPutMatrix "Rest_t0", Range(Worksheets(tab2).Cells(Start, 8), Worksheets(tab2).Cells(Start - 1 + noAssets, 8))
MLPutMatrix "Rest_turnover", Range(Worksheets(tab2).Cells(Start + noAssets, 8), Worksheets(tab2).Cells(Start + noAssets, 8))
'
MLPutMatrix "Rest_extra_A", Range(Worksheets(tab2).Cells(Start + noAssets + 3, 2), Worksheets(tab2).Cells(Start + 2 + 2 * noAssets, 7))
MLPutMatrix "Rest_extra_b", Range(Worksheets(tab2).Cells(Start + 3 + 2 * noAssets, 2), Worksheets(tab2).Cells(Start + 3 + 2 * noAssets, 7))
MLPutMatrix "Rest_extra", Range(Worksheets(tab2).Cells(Start + noAssets + 2, 2), Worksheets(tab2).Cells(Start + 2 + noAssets, 7))

MLEValstring ("PC2012_optimalisatie")


''na optimalisatie doet ie dit.
For i = 1 To (noSteps + 1)
        tabblad_naam = "Sheet1"
        Worksheets(tabblad_naam).Activate
        Cells(1, 2).Value = i
        MLPutMatrix "view_nr", Range("B1")
        MLEValstring ("hulp1 = mix_eval(:,:,view_nr)")
        MLEValstring ("hulp2 = mix_r2(view_nr,:)")
        cel_naam = "B" & 4 + (i - 1) * (noAssets + 3)
        cel_naam_end = "O" & 11 + (i - 1) * (noAssets + 3)
        Range(cel_naam, cel_naam_end).ClearContents
        MlGetMatrix "hulp1", cel_naam
        MatlabRequest
        
        
        For j = 1 To noAssets
        Worksheets(tab4).Range("scenariosSchadusRendementen").Offset(noAssets + 3 + j, i).Value = Worksheets(tabblad_naam).Range(cel_naam).Offset(j - 1#).Value
        Next j
        
        cel_naam = "G" & 3 + (i - 1) * (noAssets + 3)
        MlGetMatrix "hulp2", cel_naam
        MatlabRequest
        Cells(1, 2).ClearContents
Next i





'nrcat = 7 'omdat er zeven asset classes zijn exclusief de nominale matching portefeuille.
'
'For i = 1 To 8
'    If Sheets(tab1).Cells(19 + i, 9) = "Ja" Then
'        tabblad_naam = "Samenvatting mixen - return"
'        Worksheets(tabblad_naam).Activate
'        Cells(1, 2).Value = i
'        MLPutMatrix "view_nr", Range("B1")
'        MLEValstring ("hulp1 = rmix_eval(:,:,view_nr)")
'        MLEValstring ("hulp2 = rmix_r2(view_nr,:)")
'        cel1 = "B" & 4 + (i - 1) * (nrcat + 3)
'        cel2 = "N" & 3 + (i - 1) * (nrcat + 3) + nrcat
'        Range(cel1, cel2).ClearContents
'        cel1 = "G" & 3 + (i - 1) * (nrcat + 3)
'        cel2 = "N" & 3 + (i - 1) * (nrcat + 3)
'        Range(cel1, cel2).ClearContents
'        cel_naam = "B" & 4 + (i - 1) * (nrcat + 3)
'        MlGetMatrix "hulp1", cel_naam
'        MatlabRequest
'        cel_naam = "G" & 3 + (i - 1) * (nrcat + 3)
'        MlGetMatrix "hulp2", cel_naam
'        MatlabRequest
'        Cells(1, 2).ClearContents
'    End If
'Next i


End With

Worksheets(tab4).Activate

End Sub





