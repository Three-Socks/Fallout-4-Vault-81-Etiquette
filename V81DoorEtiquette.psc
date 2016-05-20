Scriptname V81DoorEtiquette extends ObjectReference

ObjectReference Property VaultDoor Auto Const
ObjectReference Property VaultDoorConsole Auto Const
ObjectReference Property VaultDoorKlaxonLights01 Auto Const
ObjectReference Property VaultDoorKlaxonLights02 Auto Const
ObjectReference Property VaultDoorConsoleFurniture Auto Const

Quest Property V81_00_Intro Auto Const

GlobalVariable Property Vault81DoorEtiquette_state Auto

InputEnableLayer Property VaultDoorConsoleLayer Auto Hidden

Bool Property RunVaultDoorInit Auto Const

Event OnCellLoad()
	debug.trace("V81DoorEtiquette - OnCellLoad")

	; Dont run unless the V81_00_Intro quest is completed
	If (V81_00_Intro.IsCompleted())

		debug.trace("V81DoorEtiquette - V81_00_Intro IsCompleted true")

		; Disable original console
		VaultDoorConsole.Disable()

		; Enable and reset our new console
		Self.Enable()
		Self.PlayAnimation("reset")
		Self.BlockActivation(False, False)

		Vault81DoorEtiquette_state.SetValue(0)

		; Run init code if property allows
		If RunVaultDoorInit == 1
			debug.trace("V81DoorEtiquette - RunVaultDoorInit = 1")

			; Reset VaultDoor anim
			VaultDoor.PlayAnimation("reset")

			; Reset & disable KlaxonLightGlow and linked KlaxonLight
			VaultDoorKlaxonLights01.PlayAnimation("reset")
			VaultDoorKlaxonLights02.PlayAnimation("reset")
			VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights01.Disable()
			VaultDoorKlaxonLights02.Disable()
		EndIf
	Else
		debug.trace("V81DoorEtiquette - disable/block console")

		; V81_00_Intro is not completed yet so block our console
		Self.BlockActivation(True, True)
		Self.Disable()
	EndIf
EndEvent

; Clean up incase of mod uninstall
Event OnCellDetach()
	; Revert our damage done to the cell and set everything back to how it was
	Self.Disable()
	VaultDoorConsole.Enable()
EndEvent

Event OnActivate(ObjectReference akActionRef)
	Actor PlayerREF = Game.GetPlayer()

	debug.trace("V81DoorEtiquette - OnActivate")

	; Dont run unless the V81_00_Intro quest is completed and akActionRef is player and door state is closed
	If (akActionRef == PlayerREF && V81_00_Intro.IsCompleted() && Vault81DoorEtiquette_state.GetValue() == 0)
		debug.trace("V81DoorEtiquette - OnActivate check1")

		if PlayerREF.IsInCombat()
			debug.trace("V81DoorEtiquette - OnActivate check combat")

			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			EnableKlaxonLights()
			OpenVaultDoor()
			Vault81DoorEtiquette_state.SetValue(1)
		ElseIf PlayerREF.IsInPowerArmor()
			debug.trace("V81DoorEtiquette - OnActivate check power armor")

			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			EnableKlaxonLights()
			OpenVaultDoor()
			Vault81DoorEtiquette_state.SetValue(1)
		ElseIf PlayerREF.GetSitState() != 0
			debug.trace("V81DoorEtiquette - OnActivate check GetSitState")
			; Don't do a thing
		else
			debug.trace("V81DoorEtiquette - OnActivate check2")

			;disable VATS controls 
			VaultDoorConsoleLayer = InputEnableLayer.Create()
			VaultDoorConsoleLayer.EnableVATS(False)
			Self.BlockActivation(True, True)

			;put player in the furniture 
			VaultDoorConsoleFurniture.Activate(PlayerREF)

			;wait for the pipboy animation to finish
			RegisterForAnimationEvent(PlayerREF, "On")
			;wait for the player button press anim
			RegisterForAnimationEvent(PlayerREF, "Play01")
			;wait for the button press to finish
			RegisterForAnimationEvent(Self, "stage4")

			Vault81DoorEtiquette_state.SetValue(1)

			debug.trace("V81DoorEtiquette - OnActivate check2 done")
		EndIf
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	Actor PlayerREF = Game.GetPlayer()

	debug.trace("V81DoorEtiquette - OnAnimationEvent")

	;player plugs in the pipboy
	If (akSource == PlayerREF) && (asEventNAme == "On")
		debug.trace("V81DoorEtiquette - OnAnimationEvent On")

		UnregisterForAnimationEvent(PlayerREF, "On")
		;flip open the glass
		Self.PlayAnimation("Stage2")
		;play the SWF files on the pipboy
		Game.ShowPipboyPlugin()
	EndIf

	;player presses the button
	If (akSource == PlayerREF) && (asEventName == "Play01")
		debug.trace("V81DoorEtiquette - OnAnimationEvent Play01")

		;depress button animation
		Self.PlayAnimation("Stage3")

		EnableKlaxonLights()
		OpenVaultDoor()
		UnRegisterForAnimationEvent(PlayerREF, "Play01")
	EndIf

	;if the vault control panel sequence is complete
	If (akSource == Self) && (asEventName == "stage4")
		debug.trace("V81DoorEtiquette - OnAnimationEvent stage4")

		UnRegisterForAnimationEvent(Self, "stage4")
		;allow VATS again and delete layer
		VaultDoorConsoleLayer.EnableVATS(True)
		VaultDoorConsoleLayer = None
	EndIf
EndEvent

Function EnableKlaxonLights()
	debug.trace("V81DoorEtiquette - EnableKlaxonLights")
	
	; Enable and animate KlaxonLightGlow and linked KlaxonLight
	VaultDoorKlaxonLights01.Enable()
	VaultDoorKlaxonLights02.Enable()
	VaultDoorKlaxonLights01.GetLinkedRef().Enable()
	VaultDoorKlaxonLights02.GetLinkedRef().Enable()
	VaultDoorKlaxonLights01.PlayAnimation("Stage2")
	VaultDoorKlaxonLights02.PlayAnimation("Stage2")
	VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation("Stage2")
	VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation("Stage2")
EndFunction

Function OpenVaultDoor()
	debug.trace("V81DoorEtiquette - OpenVaultDoor")

	; Reset VaultDoor again to make sure we never get stuck inside.
	;VaultDoor.PlayAnimation("reset")

	; Open VaultDoor
	VaultDoor.PlayAnimation("Stage2")
EndFunction

