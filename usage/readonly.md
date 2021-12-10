# Readonly

You can use `attr_readonly :title, :author` to prevent assign value to attribute after initialized.

You can use `enable_readonly!` and `disable_readonly!` to control the behavior.

**Important: It's no effect with embeds or array attributes !!!**

#### enable\_attr\_readonly!, disable\_attr\_readonly!

#### attr\_readonly\_enabled?

#### without\_attr\_readonly(\&blk)

#### readonly\_attribute?(attribute)

#### readonly!, readonly?

Mark the current model instance as `readonly`, which prevents any future attempts to save or update. The instance is still accessible, just frozen.

The transition to `readonly`, is one-directional and cannot be reversed. If you need to write to this instance again, you'll have to `find` it again. This is different from marking an individual attribute as `readonly`, which can be reversed.

### Class methods

#### readonly\_attributes

Returns a Set of attributes that are marked with `attr_readonly` in your AllFutures class. Attributes in the Set are presented as Strings.
