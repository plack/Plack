package NullPackage;
# Do nothing class, there should be no code or symbols defined here..
# Loading this works fine in 5.70, but a die was introduced in 5.80 which caused
# it to fail. This has been changed to a warning to maintain back-compat.
# See Catalyst::Utils::ensure_class_loaded() for more info.
1;

