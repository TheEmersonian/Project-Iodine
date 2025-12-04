Blocks have positive id's, other items have negative id's, no item has id 0


ERROR CODES:
	1 = tried to convert a block name that isn't in the game to a block id 
	2 = tried to convert a block id that isn't in the game to a block name 

# BUGS: 
	Placing grass crashes the game
	Sideways movement does not work properly
	Deep stone doesnt have an icon
# FIXED BUGS:
	Select inventory square and mouse no go back - fixed (was setting mouse mode to confined instead of captured when closing the inventory)
	Game crashes when picking up items - fixed (was checking the raycasts collider after removing it)
	When opening the inventory, you keep moving if you were already and some wierd physics happens
	A bunch of inventory bugs caused because items are passed by reference.  This took like 2 days but now I know how to avoid it
	
	

# TODO: 
	Selected item is held
	3d item textures
	
	Stats:
		Movement Speed - done
		Jump Strength - done
		Health (also get health working) - added as attribute but does nil
		Reach
	
	Full Inventory Support - partially done
	Items: {
		Better inventory managemtner items
		item to control where the mouse appears
		Items that hold+pickup unstackable items
		items that can automate certain tasks
		A way to add visual affects to items
		most items have cooldowns
		specail item catagories: [
			Block manipulation:
				short ranged, conditional, takes energy
			Item Manipulation
			Movement manipulation
			Material processing
			Information gathering
			Status infliction
			Status cleansing
			Damage types
			Defense types
			Energy / resource routing
			Structural construction
			Environmental manipulation
			Automation / timed actions
		]
	}
	Entities
	Better Generation
	Enchantments: {
		Easily accessable enchantment (craftable item?) that blocks another enchantment from appearing.  
		less +stats more passive-active abilities.  In some cases +stats functions as an ability
		enchant to make armor not appear/appear as a lower level
		enchant to walk through dropped blocks
		Quantum Storage (maxlvl: 5): Allows exclusive enchantments to be added together, press $key to switch between them over the course of 5 seconds, -1 per enclvl
		Reverberate: Emits a omnidirectional wave that copies your last action, so you can hit, place a block, or throw a potion, etc, and it will be copied on all valid targets within range.  	
	}

# DONE:
	Blocks
	Basic World Gen
	Breaking Blocks
	Placing Blocks
	Blocks Drop Items
	Pickup Items
	Block Highlight
	Basic UI
	Primitive f3 Menu
	Inventory that allows moving of items
	Physical dropped blocks
	dropped item merging - the larger the stack the more mass it has and the longer it takes to merge
	Sprinting
	Inventory that more closely mirrors the minecraft one
	Chunks generate around player, save to file, and load from file (maybe loading doesnt work completely tho)
