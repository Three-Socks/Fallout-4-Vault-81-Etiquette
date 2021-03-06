Scriptname Vault114AutoClose extends ObjectReference

ObjectReference Property VaultDoor Auto Const
ObjectReference Property VaultDoorConsole Auto Const
ObjectReference Property VaultDoorKlaxonLights01 Auto Const
ObjectReference Property VaultDoorKlaxonLights02 Auto Const
ObjectReference Property VaultDoorKlaxonLights03 Auto Const
ObjectReference Property VaultDoorKlaxonLights04 Auto Const
ObjectReference Property VDoorCollision Auto Const

Quest Property DN142 Auto

GlobalVariable Property Vault114AutoClose_state Auto

InputEnableLayer Property VaultDoorConsoleLayer Auto Hidden

Keyword Property LinkVaultDoorConsoleFurniture Auto

Bool Property RunVaultDoorInit Auto Const

Event OnCellLoad()

	Debug.Trace("Vault114AutoClose - OnCellLoad")

	; Dont run unless the DN142 quest is completed
	If (DN142.IsStageDone(50))

		Debug.Trace("Vault114AutoClose - OnCellLoad - Run")

		; Disable original console
		VaultDoorConsole.Disable()

		; Enable and reset our new console
		Self.Enable()
		Self.PlayAnimation("reset")
		Self.BlockActivation(False, False)

		Vault114AutoClose_state.SetValue(0)

		; Run init code if property allows
		If RunVaultDoorInit == 1
			Debug.Trace("Vault114AutoClose - OnCellLoad -  RunInit")

			; Reset VaultDoor anim
			VaultDoor.PlayAnimation("reset")

			; Reset & disable KlaxonLightGlow and linked KlaxonLight
			ToggleKlaxonLights(false)
		EndIf
	Else
		; DN142 is not completed yet so block our console
		Debug.Trace("Vault114AutoClose - OnCellLoad -  NotRun")
		Self.BlockActivation(True, True)
		Self.Disable()
	EndIf
EndEvent

; Clean up incase of mod uninstall
Event OnCellDetach()
	Debug.Trace("Vault114AutoClose - OnCellDetach")

	; !! TODO Lights?

	; Revert our damage done to the cell and set everything back to how it was
	Self.Disable()
	VaultDoorConsole.Enable()
	VDoorCollision.Enable()
EndEvent

Event OnActivate(ObjectReference akActionRef)
	Actor PlayerREF = Game.GetPlayer()
	ObjectReference PlayerFurnitureREF = Self.GetLinkedRef(LinkVaultDoorConsoleFurniture)

	Debug.Trace("Vault114AutoClose - OnActivate")

	; Dont run unless the DN142 quest is completed and akActionRef is player and door state is closed
	If (akActionRef == PlayerREF && DN142.IsStageDone(50) && Vault114AutoClose_state.GetValue() == 0)
		Debug.Trace("Vault114AutoClose - OnActivate - Run")

		if PlayerREF.IsInCombat()
			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			ToggleKlaxonLights(true)
			OpenVaultDoor()
			Vault114AutoClose_state.SetValue(1)
		ElseIf PlayerREF.IsInPowerArmor()
			; skip the animation and go directly to opening everything
			Self.BlockActivation(True, True)
			Self.PlayAnimation("Stage2")
			Utility.Wait(2.0)
			Self.PlayAnimation("Stage3")

			ToggleKlaxonLights(true)
			OpenVaultDoor()
			Vault114AutoClose_state.SetValue(1)
		ElseIf PlayerREF.GetSitState() != 0
			; Don't do a thing
		else
			Debug.Trace("Vault114AutoClose - OnActivate -  Run2")

			;disable VATS controls 
			VaultDoorConsoleLayer = InputEnableLayer.Create()
			VaultDoorConsoleLayer.EnableVATS(False)
			Self.BlockActivation(True, True)

			;put player in the furniture 
			PlayerFurnitureREF.Activate(PlayerREF)

			;wait for the pipboy animation to finish
			RegisterForAnimationEvent(PlayerREF, "On")
			;wait for the player button press anim
			RegisterForAnimationEvent(PlayerREF, "Play01")
			;wait for the button press to finish
			RegisterForAnimationEvent(Self, "stage4")

			;patch 1.3 - 89054 - if the player ever gets up from the furniture (such as being hit) we need to know
			RegisterForRemoteEvent(PlayerREF, "OnGetUp")

			Vault114AutoClose_state.SetValue(1)
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
		;depress button animation
		Self.PlayAnimation("Stage3")
		
		ToggleKlaxonLights(true)
		OpenVaultDoor()
		UnRegisterForAnimationEvent(PlayerREF, "Play01")
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
	If (akSender == PlayerREF) && (akFurniture == Self.GetLinkedRef(LinkVaultDoorConsoleFurniture))
		ResetVaultConsole()
	EndIf
EndEvent

Function ToggleKlaxonLights(bool enable)

	Debug.Trace("Vault114AutoClose - ToggleKlaxonLights")

	; Toggle and animate KlaxonLightGlow and linked KlaxonLight
	string animation

	If enable
		VaultDoorKlaxonLights01.Enable()
		VaultDoorKlaxonLights02.Enable()
		VaultDoorKlaxonLights03.Enable()
		VaultDoorKlaxonLights04.Enable()
		VaultDoorKlaxonLights01.GetLinkedRef().Enable()
		VaultDoorKlaxonLights02.GetLinkedRef().Enable()
		VaultDoorKlaxonLights03.GetLinkedRef().Enable()
		VaultDoorKlaxonLights04.GetLinkedRef().Enable()
		animation = "Stage2"
	else
		animation = "reset"		
	EndIf

	VaultDoorKlaxonLights01.PlayAnimation(animation)
	VaultDoorKlaxonLights02.PlayAnimation(animation)
	VaultDoorKlaxonLights03.PlayAnimation(animation)
	VaultDoorKlaxonLights04.PlayAnimation(animation)
	VaultDoorKlaxonLights01.GetLinkedRef().PlayAnimation(animation)
	VaultDoorKlaxonLights02.GetLinkedRef().PlayAnimation(animation)
	VaultDoorKlaxonLights03.GetLinkedRef().PlayAnimation(animation)
	VaultDoorKlaxonLights04.GetLinkedRef().PlayAnimation(animation)

	If (enable == false)
		VaultDoorKlaxonLights01.Disable()
		VaultDoorKlaxonLights02.Disable()
		VaultDoorKlaxonLights03.Disable()
		VaultDoorKlaxonLights04.Disable()
	EndIf
EndFunction

Function OpenVaultDoor()

	Debug.Trace("Vault114AutoClose - OpenVaultDoor")

	; Reset VaultDoor again to make sure we never get stuck inside.
	VaultDoor.PlayAnimation("reset")

	; Open VaultDoor
	VaultDoor.PlayAnimation("Stage2")

	; Disable Vault 114 collision
	VDoorCollision.Disable()
EndFunction
