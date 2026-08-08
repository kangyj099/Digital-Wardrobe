# Needs

## ① Clothing understanding/management needs (essential)

**→ Connected features:** Clothing archiving, location memo, tag search

- The total amount of clothes and shoes is very large
- Clothes are often stored in stacked boxes rather than hung, making it difficult to know what items are actually owned
- Due to weak organizational habits, physical categorization is not consistently maintained
- As a result, two recurring problems occur: “cannot find clothes” + “cannot remember what clothes I own”

## ② Outfit memory / taste understanding needs (retention)

**→ Connected feature:** Style Log

- Due to repetitive daily routines (a “hamster wheel” lifestyle), users tend to fall into a pattern of wearing the same clothes without actively thinking about outfits
- There is no retained memory of how outfits were styled in the past
- There is a need to objectively understand which clothes are worn frequently or preferred (based on wear frequency)
- There is a desire to later reference the mood/atmosphere of specific outfits worn in the past

> **Note:** “I want to organize my physical closet by category” is a personal goal, but it is unrelated to the app’s functional scope and does not influence the system design.

# Persona

**The creator themselves — excessive amount of clothes & shoes + poor at organization**

- Owns an extremely large number of clothes/shoes (enough to fill a room: 4 fully packed clothing racks + many boxes)
- Due to weak organization habits, items are stored in stacked piles rather than being properly hung
- Because there are too many clothes and they are poorly managed, there are many items that the user forgets they even own
- Sometimes cannot find clothes because their physical storage location is forgotten
- Due to repetitive daily routines, outfit decisions become habitual, leading to repeated use of the same clothes
- The user wants all information about “what I own,” “what I wear often,” and “what looks good when worn” to exist as records rather than just memory

# Key Feature

| Feature                                                        | Solved Need                                                                                                                                                                                                   | Priority                                                                                                                |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| ① Clothing Archiving <br>(Auto categorization + location memo) | Solves the problem of not knowing what clothes are owned and being unable to physically find them. <br><br>Tag-based browsing + memos (e.g., “box in 3rd closet compartment”) ensures no item is ever “lost.” | Essential — without this, there is no reason for the app to exist                                                       |
| ③ Outfit Archiving <br>(OOTD logging + history)                | Breaks habitual outfit patterns and enables users to reflect on past outfits, understand preferences via wear frequency, and revisit moods/styles                                                             | Retention core — not strictly required, but without it user interest drops significantly, reducing long-term engagement |

# Design implications

- **① is a utility-oriented feature** → core quality criteria are accuracy and speed (fast registration and fast retrieval are essential)
- **③ is a retention/engagement-oriented feature** → core quality criteria are whether the act of logging feels enjoyable or meaningful (e.g., visually showing wear frequency, making past logs satisfying to revisit)

Since the two features serve different purposes, the UI/UX should reflect different tones:

- **①:** “fast capture / fast search flow”
- **③:** “reflection and discovery flow”
