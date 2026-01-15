Blocks have positive id's, other items have negative id's, no item has id 0


ERROR CODES:
	1 = tried to convert a block name that isn't in the game to a block id 
	2 = tried to convert a block id that isn't in the game to a block name 

# BUGS: 
	Placing grass crashes the game
	Sideways movement does not work properly
# FIXED BUGS:
	Select inventory square and mouse no go back - fixed (was setting mouse mode to confined instead of captured when closing the inventory)
	Game crashes when picking up items - fixed (was checking the raycasts collider after removing it)
	When opening the inventory, you keep moving if you were already and some wierd physics happens
	A bunch of inventory bugs caused because items are passed by reference.  This took like 2 days but now I know how to avoid it
	
	

# TODO: 
	
	
	
	crafting
	player body is a physical thing with kenematics
	Selected item is held
	3d item textures
	
	Stats:
		Movement Speed - done
		Jump Strength - done
		Health (also get health working) - added as attribute but does nil
		Reach
	
	Fully fleshed out geology - use this as a template: https://www.youtube.com/watch?v=b4e7mTRB7qg
	think about the slope in blocks for some parts of worldgen, the slope of the noise might not be very high but when it switches from one block to another (because its integers) we might wanna consider that
	Full Inventory Support - partially done
	Generation that reads/writes some values to/from global variables so for instance we don't have to recompute the vertical heightmap for every chunk (vertically)
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
	Pickup Items
	Basic UI
	Primitive f3 Menu
	Physical dropped blocks
	dropped item merging - the larger the stack the more mass it has and the longer it takes to merge
	Sprinting
	Inventory that more closely mirrors the minecraft one
	Chunks generate around player, save to file, and load from file (maybe loading doesnt work completely tho)
	Blocks Drop Items (for the second time)
	More exxagerated terrain generation with rare anamolies
	Inventory that allows moving of items (for the second time)
