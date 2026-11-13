# PASS 302A Blueprint Map and Ownership Manual Checklist

Use this checklist against the deployed or locally served PASS 302A build with a real signed-in account that has existing Blueprint ownership and historical Blueprint drop reports.

## Ownership Hydration

- [ ] Hard refresh while logged in.
- [ ] Blueprint grid shows a synchronising state rather than false zero ownership.
- [ ] Owned count resolves correctly after hydration.
- [ ] Owned tile states are restored.
- [ ] Duplicate counts are restored.
- [ ] No empty ownership write is triggered during initial loading.
- [ ] Logout.
- [ ] Login to a different account.
- [ ] No ownership leaks between accounts.
- [ ] Return to the original account.
- [ ] Original ownership returns.

## Raid Intelligence Placement

- [ ] Open Raid Intelligence.
- [ ] Select Buried City Surface.
- [ ] Confirm the Town Hall report is anchored at Town Hall.
- [ ] Confirm the Main Street report is anchored at Main Street.
- [ ] Confirm the Gas Station report is anchored at Gas Station.
- [ ] Confirm the Abandoned Highway Camp report is anchored at Abandoned Highway Camp.
- [ ] Confirm First Wave Cache follows only an explicit canonical marker, registered alias, safe legacy mapping, or valid coordinate-only route.
- [ ] Confirm First Wave Cache does not silently become Warehouse.
- [ ] Confirm the same Blueprint reported at different POIs remains separated by location.
- [ ] Confirm unresolved named reports are review-required and do not render as a standard-user marker at a random nearby POI.

## Admin Marker Authority

- [ ] Open Admin Map and Intel Editor with an authorised admin account.
- [ ] Move one published Admin marker used by historical reports.
- [ ] Publish marker changes.
- [ ] Refresh Raid Intelligence.
- [ ] Historical reports follow the moved published marker.
- [ ] Draft marker moves do not affect standard-user Raid Intelligence placement.
- [ ] Unrelated reports do not move.

## Reported PASS 302A Cases

- [ ] Patina recorded at Town Hall renders at Town Hall, not Hospital.
- [ ] Compensator recorded at Main Street renders at Main Street.
- [ ] Extended Barrel II recorded at Gas Station renders at Gas Station, not Town Hall.
- [ ] Bobcat recorded at Abandoned Highway Camp renders at Abandoned Highway Camp, not Warehouse.
- [ ] Alto recorded at First Wave Cache uses only supported First Wave Cache resolution paths.
