Scriptname V81DoorEtiquette extends ObjectReference

ObjectReference Property VaultDoor Auto Const
ObjectReference Property VaultDoorConsole Auto Const
ObjectReference Property VaultDoorKlaxonLights01 Auto Const
ObjectReference Property VaultDoorKlaxonLights02 Auto Const
Quest Property V81_00_Intro Auto
GlobalVariable Property Vault81Etiquette_door_state Auto

Event OnCellLoad()
	If (V81_00_Intro.GetStageDone(1000))
		VaultDoorConsole.Disable()
		Self.Enable()
		Self.BlockActivation(False, False)

		If Vault81Etiquette_door_state.GetValue() == 0
			VaultDoor.PlayAnimation("reset")
			VaultDoorKlaxonLights01.PlayAnimation("reset")
			VaultDoorKlaxonLights02.PlayAnimation("reset")
			VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights01.Disable()
			VaultDoorKlaxonLights02.Disable()

			Vault81Etiquette_door_state.SetValue(1)
		EndIf
	Else
		Self.Disable()
		; TODO: Remove
		Debug.MessageBox("V81DoorEtiquette Disabled self")
	EndIf
EndEvent

Event OnActivate(ObjectReference akActionRef)
	If (akActionRef == Game.GetPlayer() && V81_00_Intro.GetStageDone(1000))
		
		If Vault81Etiquette_door_state.GetValue() == 1
			utility.wait(8)
			VaultDoorKlaxonLights01.Enable()
			VaultDoorKlaxonLights02.Enable()
			VaultDoorKlaxonLights01.GetLinkedRef().Enable()
			VaultDoorKlaxonLights02.GetLinkedRef().Enable()
			VaultDoorKlaxonLights01.PlayAnimation("Stage2")
			VaultDoorKlaxonLights02.PlayAnimation("Stage2")
			VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation("Stage2")
			VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation("Stage2")
			VaultDoor.PlayAnimation("Stage2")
			Vault81Etiquette_door_state.SetValue(0)
		EndIf
	EndIf
EndEvent
