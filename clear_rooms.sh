#!/bin/bash
# Script to clear iCloud KV Store rooms data
# Run this to delete old rooms with "User" usernames

echo "This will clear all rooms from iCloud Key-Value Storage"
echo "Run the following in Xcode's debug console or in your app:"
echo ""
echo "NSUbiquitousKeyValueStore.default.removeObject(forKey: \"layoverlounge.rooms\")"
echo "NSUbiquitousKeyValueStore.default.synchronize()"
