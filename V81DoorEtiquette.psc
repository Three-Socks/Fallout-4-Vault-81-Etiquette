Scriptname V81DoorEtiquette extends ObjectReference

ObjectReference Property VaultDoor Auto Const
ObjectReference Property VaultDoorConsole Auto Const
ObjectReference Property VaultDoorKlaxonLights01 Auto Const
ObjectReference Property VaultDoorKlaxonLights02 Auto Const
Quest Property V81_00_Intro Auto
GlobalVariable Property Vault81Etiquette_door_state Auto

ObjectReference Property VaultDoorConsoleFurniture Auto
InputEnableLayer Property VaultDoorConsoleLayer Auto Hidden

Bool Property RunVaultDoorInit Auto Const

Event OnCellLoad()
	; Dont run unless the V81_00_Intro quest is completed
	If (V81_00_Intro.IsCompleted())

		; Disable original console
		VaultDoorConsole.Disable()

		; Enable and reset our new console
		Self.Enable()
		;Self.PlayAnimation("reset")
		Self.BlockActivation(False, False)

		; Run init code if door state is closed and allowed to run init
		If (Vault81Etiquette_door_state.GetValue() == 0 && RunVaultDoorInit == 1)
			; Reset VaultDoor anim
			VaultDoor.PlayAnimation("reset")

			; Reset & disable KlaxonLightGlow and linked KlaxonLight
			VaultDoorKlaxonLights01.PlayAnimation("reset")
			VaultDoorKlaxonLights02.PlayAnimation("reset")
			VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation("reset")
			VaultDoorKlaxonLights01.Disable()
			VaultDoorKlaxonLights02.Disable()

			Vault81Etiquette_door_state.SetValue(1)
		EndIf
	Else
		; V81_00_Intro is not completed yet so block our console
		;Self.BlockActivation(True, True)
		Self.Disable()
		; TODO: Remove
		Debug.MessageBox("V81DoorEtiquette Disabled self")
	EndIf
EndEvent

Event OnActivate(ObjectReference akActionRef)
	Actor PlayerREF = Game.GetPlayer()

	; Dont run unless the V81_00_Intro quest is completed and akActionRef is player and door state is closed
	If (akActionRef == PlayerREF && V81_00_Intro.IsCompleted() && Vault81Etiquette_door_state.GetValue() == 1)
		if PlayerREF.IsInCombat()
			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			EnableKlaxonLights()
			OpenVaultDoor()
			Vault81Etiquette_door_state.SetValue(0)
		ElseIf PlayerREF.IsInPowerArmor()
			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			EnableKlaxonLights()
			OpenVaultDoor()
			Vault81Etiquette_door_state.SetValue(0)
		ElseIf PlayerREF.GetSitState() != 0
			; Don't do a thing
		else
			;disable VATS controls 
			Debug.trace("V81DoorEtiquette OnActivate")
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

			;patch 1.3 - 89054 - if the player ever gets up from the furniture (such as being hit) we need to know
			RegisterForRemoteEvent(PlayerREF, "OnGetUp")

			Vault81Etiquette_door_state.SetValue(0)
		EndIf
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	Actor PlayerREF = Game.GetPlayer()

	;player plugs in the pipboy
	If (akSource == PlayerREF) && (asEventNAme == "On")
		UnregisterForAnimationEvent(PlayerREF, "On")
		;flip open the glass
		Self.PlayAnimation("Stage2")
		;play the SWF files on the pipboy
		Game.ShowPipboyPlugin()
	EndIf

	;player presses the button
	If (akSource == PlayerREF) && (asEventName == "Play01")
		EnableKlaxonLights()
		OpenVaultDoor()
		UnRegisterForAnimationEvent(PlayerREF, "Play01")
		;depress button animation
		Self.PlayAnimation("Stage3")
	EndIf

	;if the vault control panel sequence is complete
	If (akSource == Self) && (asEventName == "stage4")
		UnRegisterForAnimationEvent(Self, "stage4")
		;allow VATS again and delete layer
		VaultDoorConsoleLayer.EnableVATS(True)
		VaultDoorConsoleLayer = None

		;patch 1.3 - 89054 - no need to catch the getup event anymore
		UnRegisterForRemoteEvent(PlayerREF, "OnGetUp")
	EndIf
EndEvent

;patch 1.3 - 89054 - if the player ever leaves the linked furniture, we need to clear the control lock and re-enable the console

;need to create a function so I can call this remotely to fix savegames already in this state
Function ResetVaultConsole()
	Actor PlayerREF = Game.GetPlayer()
	VaultDoorConsoleLayer.EnableVATS()
	VaultDoorConsoleLayer = None
	Self.BlockActivation(False, False)

	;unregister for previously registered events
	UnregisterForAllEvents()
EndFunction

Event Actor.OnGetUp(Actor akSender, ObjectReference akFurniture)
	Actor PlayerREF = Game.GetPlayer()
	If (akSender == PlayerREF) && (akFurniture == VaultDoorConsoleFurniture)
		ResetVaultConsole()
	EndIf
EndEvent

Function EnableKlaxonLights()
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
	; Reset VaultDoor again to make sure we never get stuck inside.
	VaultDoor.PlayAnimation("reset")

	; Open VaultDoor
	VaultDoor.PlayAnimation("Stage2")
EndFunction

