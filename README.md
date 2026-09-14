# WhatNext Vision Motors

## Salesforce Platform Developer Project

WhatNext Vision Motors is a Salesforce-based vehicle management
and ordering solution designed to improve vehicle inventory,
customer order processing, dealer management and operational
efficiency.

## Project Objectives

- Manage vehicle inventory
- Track vehicle stock availability
- Manage vehicle dealers
- Manage customers
- Process vehicle orders
- Manage test drives
- Manage service requests
- Prevent incorrect vehicle ordering
- Automatically process pending orders
- Automate inventory management

## Salesforce Objects

- Vehicle__c
- Vehicle_Dealer__c
- Vehicle_Order__c
- Vehicle_Customer__c
- Vehicle_Test_Drive__c
- Vehicle_Service_Request__c

## Automation

- Vehicle stock validation
- Order status management
- Stock deduction
- Test-drive reminders
- Pending order processing

## Apex Components

### VehicleOrderTrigger

Handles Vehicle Order insert and update events.

### VehicleOrderTriggerHandler

Contains business logic for stock validation and vehicle stock updates.

### VehicleOrderBatch

Processes pending vehicle orders when stock becomes available.

### VehicleOrderBatchScheduler

Schedules the Batch Apex process.

## Scheduled Processing

The batch job can run daily at midnight.

## Technologies

- Salesforce
- Apex
- Apex Trigger
- Trigger Handler
- Batch Apex
- Scheduled Apex
- Salesforce Flow
- Custom Objects
- Custom Fields
- Lookup Relationships
