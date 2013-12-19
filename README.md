Gnawts
======

![A Knotty Logo](appserver/static/bigIcon.png)
Gnawts is a Splunk app for fast detangling of supercomputer logs. The name is a pun: HPC systems have many hosts emitting many logs concurrently, which can be related or not - making these into a coherent signal and making sense of them can be like untangling many strings in a knot. Hard places in logs are called knots, this app helps you chew (gnaw) through such hard places in computer logs. And the term "log" has a nautical background, and speed is measured in knots (fast). So the name has multiple layers, just as the app has multiple layers of functionality.  In the icon, the red sky in the icon relates to gnawt's ability to help forecast storms (or not) on HPC systems, similar to red skies at sea.


Configuration
-------------

1. Install [Splunk](http://www.splunk.com/).
2. Install the [Sideview Utilities App](http://www.sideviewapps.com/).
3. Install the [Gnawts app using Splunkbase](http://splunk-base.splunk.com/apps/gnawts).
4. See ```default/data/ui/views/Help.xml``` for additional details.

Additional Information
----------------------

* [Bridging the gaps: joining information sources with Splunk](http://static.usenix.org/event/slaml10/tech/full_papers/Stearley.pdf)
  * Lord, K. M., Corwell, S. E., & Stearley, J. R. (2010).
  * (No. SAND2010-7414C). Sandia National Laboratories.
* [A State-Machine Approach to Disambiguating Supercomputer Event Logs](https://www.usenix.org/system/files/mad12-final8.pdf)
  * Stearley, J., Ballance, R., & Bauman, L. (2012).
  * (No. SAND2012-5615C). Sandia National Laboratories.

Contributions
------------

See the included AUTHORS.md file for a list of contributors.

To contribute to Gnawts, see the included CONTRIBUTIONS.md file.
