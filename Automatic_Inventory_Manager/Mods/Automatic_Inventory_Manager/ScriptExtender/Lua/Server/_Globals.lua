--- Since moving items is an event, not a DB operation, need to track which items are currently in the queue
--- to be moved, but haven't left the OG inventory yet, so our math in the processor works
TEMPLATES_BEING_TRANSFERRED = {}

-- Larians Tags(Public/shared/Tags/)

-- Custom Tags (/Public/Automatic_Inventory_Manager/Tags)
TAG_AIM_PROCESSED = "add41a41-a1a8-4405-ae7f-ce12a0788a1a"
TAG_AIM_MARK_FOR_DELETION = "4b640e87-509b-4c90-a4e7-144c224314b0"

-- CUSTOM EVENTS

EVENT_CLEAR_CUSTOM_TAGS_START = "AIM_CLEAR_CUSTOM_TAGS_START"
EVENT_CLEAR_CUSTOM_TAGS_END = "AIM_CLEAR_CUSTOM_TAGS_END"

EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_START = "AIM_REBUILD_ITEMS_START"
EVENT_ITERATE_ITEMS_TO_REBUILD_THEM_END = "AIM_REBUILD_ITEMS_END"
