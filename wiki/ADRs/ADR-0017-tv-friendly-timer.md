# TV friendly challenge timer

The TV picture-pairs and animal-photo quiz keep untimed play as the default. An optional gentle timer is a transient presentation aid, separate from matching rules, answers, evidence and persistence.

Use one main-actor observable clock with an injected monotonic time source. Independent pause reasons prevent closing options from accidentally resuming a timer still paused by backgrounding or a hint. Expiry freezes the clock and offers more time or untimed play on the same item. It never submits an answer, changes points, or completes a learning stage.

Views own transient clock instances. A small TV display drives refresh while visible; clock tests advance an injected time source without waiting. Completion and exit stop the clock. No new persisted keys, migration or child-history changes are required.
