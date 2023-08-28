## SOFIA Changelog

#### v0.6.1-beta (2023-08-xx)

- List order is more stable when two players have a strictly similar rank

#### v0.6.0-beta (2023-08-25)

- Write in the chat when a guild player levels up every 10 levels

#### v0.5.1-beta (2023-07-30)

- Omit the 'at least' detail when we witnessed a level up
- Can now reset the window multiple times with /sofia reset
- Can now purge roster data multiple times with /sofia delete
- Level up date and time now come from GetServerTime()
- Fixed almost impercetible rendering issues

#### v0.5.0-beta (2023-07-29)

- Settings button to open a settings popup menu
- Option to sort by level or by recent level up
- Option to set the font size / tag height
- Option to set the spacing between tags

#### v0.4.0-beta (2023-07-26)

- After more tests, the addon is ready to enter its Beta phase
- First version available on CurseForge
- Fixed texturing issues in Wrath
- Fixed roster update if your player was the highest in the guild
- Fixed date display on tooltip

#### v0.3.3-alpha (2023-07-26)

- Tooltip indicates when the player level up
- More exactly, this is when we learned that
- The tooltip says "at least" to be more accurate

#### v0.3.2-alpha (2023-07-25)

- Name tags display rank, name and level
- Lots of optimizations when refreshing the list of name tags

#### v0.3.1-alpha (2023-07-25)

- /sofia reset now only resets window settings, not the roster
- The roster can be purged with /sofia delete

#### v0.3.0-alpha (2023-07-23)

- Ability to create name tags
- Tags are allocated dynamically, based on window height

#### v0.2.1-alpha (2023-07-23)

- Fixed many issues when fetching guild info
- Track when a player leaves your guild
- Track when you die

#### v0.2.0-alpha (2023-07-22)

- System for storing character information
- Currently gathering guild info and player info

#### v0.1.0-alpha (2023-07-22)

- Public repository on GitHub
- Code cleanup to go public
- This code can be seen as an example of a 'minimal addon with one window'

#### v0.0.5-alpha (2023-07-22)

- Packaging script

#### v0.0.4-alpha (2023-07-21)

- Console commands: show, hide, toggle, reset

#### v0.0.3-alpha (2023-07-21)

- Windowing system, movable and resizable
- Window settings are saved in the database

#### v0.0.2-alpha (2023-07-21)

- Load and save database, account-wide

#### v0.0.1-alpha (2023-07-21)

- Code base, with no functionality
