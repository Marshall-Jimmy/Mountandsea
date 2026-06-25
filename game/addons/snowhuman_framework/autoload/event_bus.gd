extends Node

signal data_loaded
signal inventory_changed(owner_id: String)
signal item_collected(owner_id: String, item_id: String, count: int)
signal save_requested(slot: int)
signal save_completed(slot: int)
signal save_failed(slot: int, reason: String)
