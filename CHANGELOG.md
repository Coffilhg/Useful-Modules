# v2.0.0
- Now fully typed
- Added runtime protection for internal state
- Added `RemoveArrangementByKey`
- Added `RemoveArrangementByIndex`
- Keys can now be removed using either removal method or `Arrangement[key] = nil`
- Removed keys have their previous indices invalidated and are assigned a new index if accessed again

# v1.0.0

Published to wally & rotriever.