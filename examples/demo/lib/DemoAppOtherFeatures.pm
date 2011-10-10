package # hide from PAUSE
    DemoAppOtherFeatures;

use Catalyst qw/-Debug
                ConfigLoader
                Unicode::Encoding
                AutoCRUD/;

DemoAppOtherFeatures->config(
    root => "$FindBin::Bin/root",
    'Plugin::ConfigLoader' => { file => "$FindBin::Bin/demo_other_features.conf" },
);

DemoAppOtherFeatures->setup();
1;
