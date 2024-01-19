package olib.models.tests;

import utest.Runner;
import utest.ui.Report;

class Main
{
    public static function main()
    {
        var testRunner = new Runner();
        testRunner.addCase(new Tests());
        Report.create(testRunner);
        testRunner.run();
    }
}
