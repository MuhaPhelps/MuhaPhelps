migrate((app) => {
  try {
    const defaultUsers = app.findCollectionByNameOrId("users")
    app.delete(defaultUsers)
  } catch (_) {
    // If the default users collection is already absent, continue normally.
  }
}, (app) => {
  // No rollback is required for this preparatory migration.
})
