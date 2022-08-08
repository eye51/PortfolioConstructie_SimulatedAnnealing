Attribute VB_Name = "resetValues"

Sub Leegmaken()

Range("C3", "C10").Value = 0
Range("D3", "D10").Value = 1
Range("E3", "E11").Value = 0.99

End Sub

Sub totaalPortefeuilleMaxOpEen()

Range("D4", "D11").Value = 1


End Sub

Sub totaalPortefeuilleMinOpNul()

Range("C4", "C11").Value = 0


End Sub


Sub matchingPortefeuilleMaxOpEen()

    Range("F4", "F11").Value = 1

End Sub

Sub matchingPortefeuilleMinOpNul()
    Range("E4", "E11").Value = 0

End Sub

