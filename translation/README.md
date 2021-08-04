# Translation example

- Translate Bohemian Rhapsody from English to Spanish.
- Translate arbitrary text strings at compile-time without cost at run-time.
- Translate from 1 simple INI file, no additional tools required.
- Example is meant for Frontend web, but can be used for Backend without changes too.


# Observation

As far as I know is the only fully compile-time translation library,
imagine if your server shows translated text a million times per hour,
therefore you are doing a million translations per hour at run-time,
this library does it at compile-time instead with zero cost at run-time.


# Use

`nim js -d:danger -d:nodejs -d:ES_AR -d:iniFile="translations.cfg" example.nim`
