Attribute VB_Name = "Optimalisatie"
Sub Optimalisatie()

Dim noAssets As Integer
Dim maxNoAssets As Integer
Dim i As Integer


Dim tab0 As String


maxNoAssets = 12 ' Hardcoded max !

'Sla gebruikte instelling op

Application.ScreenUpdating = False


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

' bepaal aantal asset classes

noAssets = 0
i = 0

While (Worksheets(tab3).Range("parametersAssets").Offset(i + 1, 0).Value <> "")
    i = i + 1
Wend

noAssets = i

Worksheets(tab1).Activate


noScenarios = 8 ' Nu nog hardcoded aantal!

'ncat = 8

'Schrijf parameters naar Matlab
'IR analyse


MLPutMatrix "scen_names", Range(Worksheets(tab1).Cells(6, 1), Worksheets(tab1).Cells(5 + noScenarios, 1))
MLPutMatrix "asset_names", Range(Worksheets(tab3).Cells(4, 1), Worksheets(tab3).Cells(3 + noAssets, 1))
MLPutMatrix "ScenarioKans", Range(Worksheets(tab1).Cells(6, 2), Worksheets(tab1).Cells(5 + noScenarios, noScenarios))
MLPutMatrix "scenarios", Worksheets(tab3).Range("aantalScenarios")
MLPutMatrix "Nassets", Worksheets(tab3).Range("aantalAssets")


MLPutMatrix "MinRet", Range(Worksheets(tab1).Cells(20, 2), Worksheets(tab1).Cells(19 + noScenarios, 2))
MLPutMatrix "MinRet_actief", Range(Worksheets(tab1).Cells(20, 3), Worksheets(tab1).Cells(19 + noScenarios, 3))
MLPutMatrix "MaxTE", Range(Worksheets(tab1).Cells(20, 4), Worksheets(tab1).Cells(19 + noScenarios, 4))
MLPutMatrix "MaxTE_actief", Range(Worksheets(tab1).Cells(20, 5), Worksheets(tab1).Cells(19 + noScenarios, 5))
MLPutMatrix "MaxLPM", Range(Worksheets(tab1).Cells(20, 6), Worksheets(tab1).Cells(19 + noScenarios, 6))
MLPutMatrix "MaxLPM_actief", Range(Worksheets(tab1).Cells(20, 7), Worksheets(tab1).Cells(19 + noScenarios, 7))
MLPutMatrix "doelstelling", Range("doelstelling")
MLPutMatrix "doorrekenen", Range(Worksheets(tab1).Cells(20, 9), Worksheets(tab1).Cells(19 + noScenarios, 9))

MLPutMatrix "show_plot", Worksheets("Control panel").Range("showPlotJN")

MLPutMatrix "bm_nr", Range("B126")

MLPutMatrix "lpm_target", Range("B30")
MLPutMatrix "lpm_orde", Range("B31")

MLPutMatrix "Niter", Range("B34")
MLPutMatrix "Nport", Range("B35")

'
'MLPutMatrix "scen_names", Range("A6:A13")
'MLPutMatrix "asset_names", Worksheets(tab0).Range("A4", "A11")
'MLPutMatrix "ScenarioKans", Range("B6:H13")
'MLPutMatrix "scenarios", Worksheets(tab3).Range("B39")
'MLPutMatrix "Nassets", Worksheets(tab3).Range("B40")
'
'MLPutMatrix "MinRet", Range(Cells(20, 2), Cells(27, 2))
'MLPutMatrix "MinRet_actief", Range(Cells(20, 3), Cells(27, 3))
'MLPutMatrix "MaxTE", Range(Cells(20, 4), Cells(27, 4))
'MLPutMatrix "MaxTE_actief", Range(Cells(20, 5), Cells(27, 5))
'MLPutMatrix "MaxLPM", Range(Cells(20, 6), Cells(27, 6))
'MLPutMatrix "MaxLPM_actief", Range(Cells(20, 7), Cells(27, 7))
'MLPutMatrix "doelstelling", Range("C105:C112")
'MLPutMatrix "doorrekenen", Range(Cells(20, 9), Cells(27, 9))
'
'MLPutMatrix "show_plot", Worksheets("Control panel").Range("B36")
'
'MLPutMatrix "bm_nr", Range("B126")
'
'MLPutMatrix "lpm_target", Range("B30")
'MLPutMatrix "lpm_orde", Range("B31")
'
'MLPutMatrix "Niter", Range("B34")
'MLPutMatrix "Nport", Range("B35")

'Lees visies in
Worksheets(tab0).Activate 'absolute visies
For i = 1 To 7
    Cells(1, 2).Value = i
    MLPutMatrix "visienr", Cells(1, 2)
    MLPutMatrix "mat", Range(Cells(4 + (i - 1) * (maxNoAssets + 3), 2), Cells(noAssets + (i - 1) * (maxNoAssets + 3) + 3, noAssets + 3))
    MLEValstring ("[mu,covm] = VertaalMat(mat)")
    MLEValstring ("pars.meanmat(:,visienr) = mu;")
    MLEValstring ("pars.covmat(:,:,visienr) = covm;")
    MatlabRequest
    Cells(1, 2).ClearContents
Next i

'Lees restricties in
Start = 4
Worksheets(tab2).Activate 'restricties
MLPutMatrix "InPortefeuille", Range(Cells(115, 2), Cells(114 + noAssets, 2))
MLPutMatrix "Rest_tot", Range(Cells(Start, 3), Cells(Start - 1 + noAssets, 4))
MLPutMatrix "Rest_port", Range(Cells(Start, 5), Cells(Start - 1 + noAssets, 6))
MLPutMatrix "w_t0", Range(Cells(Start, 7), Cells(Start - 1 + noAssets, 7))
MLPutMatrix "Rest_t0", Range(Cells(Start, 8), Cells(Start - 1 + noAssets, 8))
MLPutMatrix "Rest_turnover", Range(Cells(Start + maxNoAssets, 8), Cells(Start + maxNoAssets, 8))

MLPutMatrix "Rest_extra_A", Range(Cells(Start + maxNoAssets + 3, 2), Cells(Start + 2 + maxNoAssets + noAssets, 7))
MLPutMatrix "Rest_extra_b", Range(Cells(Start + 3 + 2 * maxNoAssets, 2), Cells(Start + 3 + 2 * maxNoAssets, 7))
MLPutMatrix "Rest_extra", Range(Cells(Start + maxNoAssets + 2, 2), Cells(Start + 2 + maxNoAssets, 7))

MLEValstring ("PC2012_optimalisatie")

'na optimalisatie doet ie dit.
For i = 1 To noScenarios
    If Sheets(tab1).Cells(19 + i, 9) = "Ja" Then
        tabblad_naam = "Samenvatting mixen"
        Worksheets(tabblad_naam).Activate
        Cells(1, 2).Value = i
        MLPutMatrix "view_nr", Range("B1")
        MLEValstring ("hulp1 = mix_eval(:,:,view_nr)")
        MLEValstring ("hulp2 = mix_r2(view_nr,:)")
        cel_naam = "B" & 4 + (i - 1) * (maxNoAssets + 3)
        cel_naam_end = "O" & 15 + (i - 1) * (maxNoAssets + 3)
        Range(cel_naam, cel_naam_end).ClearContents
        MlGetMatrix "hulp1", cel_naam
        MatlabRequest
        cel_naam = "G" & 3 + (i - 1) * (maxNoAssets + 3)
        MlGetMatrix "hulp2", cel_naam
        MatlabRequest
        Cells(1, 2).ClearContents
    End If
Next i

nrcat = noAssets - 1 'omdat er (noAssets-1) asset classes zijn exclusief de nominale matching portefeuille.

For i = 1 To noScenarios
    If Sheets(tab1).Cells(19 + i, 9) = "Ja" Then
        tabblad_naam = "Samenvatting mixen - return"
        Worksheets(tabblad_naam).Activate
        Cells(1, 2).Value = i
        MLPutMatrix "view_nr", Range("B1")
        MLEValstring ("hulp1 = rmix_eval(:,:,view_nr)")
        MLEValstring ("hulp2 = rmix_r2(view_nr,:)")
        cel1 = "B" & 4 + (i - 1) * (maxNoAssets + 2)
        cel2 = "N" & 3 + (i - 1) * (maxNoAssets + 2) + (maxNoAssets - 1)
        Range(cel1, cel2).ClearContents
        cel1 = "G" & 3 + (i - 1) * (maxNoAssets + 2)
        cel2 = "N" & 3 + (i - 1) * (maxNoAssets + 2)
        Range(cel1, cel2).ClearContents
        cel_naam = "B" & 4 + (i - 1) * (maxNoAssets + 2)
        MlGetMatrix "hulp1", cel_naam
        MatlabRequest
        cel_naam = "G" & 3 + (i - 1) * (maxNoAssets + 2)
        MlGetMatrix "hulp2", cel_naam
        MatlabRequest
        Cells(1, 2).ClearContents
    End If
Next i

Worksheets("Control panel").Activate

End Sub


