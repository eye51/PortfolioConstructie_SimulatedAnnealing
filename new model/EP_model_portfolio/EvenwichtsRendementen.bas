Attribute VB_Name = "EvenwichtsRendementen"
Sub Evenwichtsrendement()

Dim noAssets As Integer
Dim i As Integer


Dim tab0 As String


tab0 = "Scenarios"
'Sla gebruikte instelling op

Application.ScreenUpdating = False

MLShowMatlabErrors ("yes")

'Leeg geheugen Matlab
MLEValstring ("clear")
MLEValstring ("P1 = path")
MLEValstring ("P2 = '\\fserver11\groups1\IC_modelportfolio\Cluster Portfolio Construction\Modelportefeuille'")
MLEValstring ("cd '\\fserver11\groups1\IC_modelportfolio\Cluster Portfolio Construction\Modelportefeuille'")
MLEValstring ("path(P2,P1)")


' bepaal aantal asset classes

noAssets = 0
i = 0

While (Worksheets(tab0).Range("parametersAssets").Offset(i + 1, 0).Value <> "")
    i = i + 1
Wend

noAssets = i
Worksheets(tab0).Range("aantalAssets").Value = noAssets

Worksheets(tab0).Activate

'Schrijf parameters naar Matlab
'Implied Return analyse

'Input voor optimalisatie
MLPutMatrix "w0", Range(Worksheets(tab0).Cells(4, 2), Worksheets(tab0).Cells(3 + noAssets, 2))
MLPutMatrix "stdev", Range(Worksheets(tab0).Cells(4, 4), Worksheets(tab0).Cells(3 + noAssets, 4))
MLPutMatrix "cormat", Range(Worksheets(tab0).Cells(4, 5), Worksheets(tab0).Cells(3 + noAssets, 4 + noAssets))
MLPutMatrix "bm_nr", Range("bmNummer")
MLPutMatrix "vast_nr", Range("assetsSpecified")         'voor bepalen evenwichts rendement heb je voro 2 asset classes gegeven returns nodig.
MLPutMatrix "vast_ret", Range("rendSpecified")          '

MLEValstring ("BepaalEvenwichtsRendement;")

MlGetMatrix "m_eq", "evenwichtRend"         'schrijf evenwichts returns (range in sheet heet "evenwichtRend")
MlGetMatrix "te", "trackingErrorHuidig"     'schrijf tracking error (range in sheet heet "trackingErrorHuidig"
MatlabRequest

'celnaam1 = "C" & 4
'celnaam2 = "C" & 3 + noAssets
'MLPutMatrix "m_eq", Range(celnaam1, celnaam2)
'celnaam1 = "B" & noAssets + 11
'celnaam2 = "E" & 2 * noAssets + 10
'MLPutMatrix "beta", Range(celnaam1, celnaam2)
'celnaam1 = "B" & 2 * noAssets + 12
'celnaam2 = "E" & 2 * noAssets + 15
'MLPutMatrix "schokken", Range(celnaam1, celnaam2)
'celnaam1 = "B" & 2 * noAssets + 16
'celnaam2 = "E" & 2 * noAssets + 16
'MLPutMatrix "gewicht", Range(celnaam1, celnaam2)'

'MLEValstring ("VerwerkVisies")
'MLEValstring ("m_view = [m_eq m_view];")

'celnaam = "I" & noAssets + 11
'MlGetMatrix "m_view", celnaam
'MatlabRequest

'Worksheets("Control panel").Activate

End Sub

