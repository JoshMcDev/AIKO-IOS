# DISAs_Solicitation_for_Enterprise_Business_Modernization_EBM_project_Attachment_2_CRD_11410

_Converted from PDF using pdftotext_

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

TABLE OF CONTENTS
EXECUTIVE SUMMARY...................................................................................................1
1 ORGANIZATIONAL OVERVIEW.............................................................................1-1
1.1
1.2
1.3
1.4

PL/DITCO BACKGROUND.................................................................................1-1
PL/DITCO MISSION......................................................................................... 1-1
ENTERPRISE BUSINESS MODERNIZATION OBJECTIVES........................................1-2
CURRENT PL/DITCO SYSTEM ENVIRONMENT....................................................1-3

2 CONCEPT OF OPERATIONS..................................................................................2-1
2.1
2.2
2.3
2.4

OPERATIONAL CONCEPT...................................................................................2-1
STAKEHOLDERS/OPERATIONAL NODES...............................................................2-3
BUSINESS PROCESS DESCRIPTION....................................................................2-4
EBM SOLUTION EXTERNAL INTERFACES............................................................2-6

3 REQUIREMENTS.....................................................................................................3-1
3.1

SYSTEM FUNCTIONALITY...................................................................................3-1

4 TRANSITION PLAN.................................................................................................4-1
5 Test and Evaluation...................................................................................................5-1

LIST OF FIGURES
Figure 1. OV-1, Operational Concept Diagram..............................................................2-3
Figure 2. Acquisition Domain General Conduct Sourcing Business Process Model.....2-5
Figure 3. To-Be SV-1, System Interface Description....................................................2-11

LIST OF TABLES
Table 1. Products and Services Procured for Buyers...................................................1-2
Table 2. EBM External System Application....................................................................2-7
Table 3. EBM High-level Transition Plan........................................................................4-1

ii
FINAL DRAFT- v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

EXECUTIVE SUMMARY
The Defense Information Technology Contracting Organization (DITCO) is a
subordinate activity of the Procurement and Logistics (PL) Directorate of the Defense
Information Systems Agency (DISA). PL/DITCO procures a wide spectrum of
information technology (IT) and long-haul telecommunications products and services for
he Department of Defense (DOD) and a number of numerous other fFederal agencies.
PL/DITCO, which has been procuring IT and telecommunications products and services
for 30 years, and has instituted a number ofa number of its streamlining initiatives into
regulatory language mostly focused on telecommunications. These initiatives can be
found in Defense Federal Acquisition Regulation (DFAR) part 239.
Issue: To successfully accomplish its procurement mission, PL/DITCO manages,
operates, and in many cases, has often developed, a group of complex software
applications across a wide range of computing environments, including client/server,
mainframe, and Web. Current systems are a combination of multiple coding languages,
platforms, and processes that have evolved duringover the past 30 years. As is the
case with many large enterprises, these applications have evolved independently over
ime and do not adhere to a consistent architecture. This inconsistency in system
configuration leads to a number ofnumerous issues:
•

Higher operations and maintenance (O&M) cost.;

•

User dissatisfaction attributeddue to anthe inability to envisionsee an end-to-end
picture of their the user’s procurement process and multiple data entry.; and

•

Inefficient use of IT resources to support business processes and to accommodate
changes in requirements.

Discussion: In January 2003, PL/DITCO’s Director and Executive Steering Committee
decided to initiate the Enterprise Business Modernization (EBM) Programject in order to
provide PL/DITCO with tools that better support the organization’s core functional
processes. The goals of the PL/DITCO EBM Project Program are as follows:to:
•

Reduce total cost of ownership.

•

Create a single integrated procurement solution that is uniformly implemented and
readily accessible worldwide.

•

Share consistent data, services, and processes across business functions and
systems applying the tenets and principles of net-centricity.

•

Provide accurate and easily retrievable information for all PL/DITCO contracting
functions and associated external users.

•

Reduce total cost of ownership by decreasing operational costs while increasing
procurement efficiency.

ES-1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

EBM must be compliant with the Acquisition Domain and DISA architectures and will
incorporate the mandated fFederal and Department of Defense (DOD) Acquisition
Domain Interim State Enterprise Procurement Enterprise Systems (ADISPES) with a
seamless information exchange. The EBM team has modeled a unified IT and telecom
contracting business process for the tTo-bBe environment and identified key functional
capabilities that are required to achieve that end state. The EBM team conducted an
assessment of current commercially available systems that could meet these
capabilities and sent out a formal Request for Information (RFI) to solicit ideas from
industry. Based on the industry responses to the RFI and commercial system
functionality, the EBM team defined a tTo-bBe EBM architecture that includes desired
systems capabilities.
Conclusion: PL/DITCO needs a solution that leverages commercially available
echnical resources that enables the organization to achieve a unified IT and telecom
contracting business process while being adaptable to accomplish unique aspects of
he telecom contracting process, e.g., Inquiry-Quote-Order (IQO) process, tariff
updates. The EBM solution must also conform to the tenets and principles of netcentricity, which allows for greater electronic management of data and collaboration
between PL/DITCO stakeholders while reducing system costs.
This Capabilities Requirement Document (CRD) provides the high-level architecture
and requirements that prospective Enterprise Business Modernization (EBM)
contractors need to design the system. The CRD is organized in five sections and
eleven appendices. The five sections discuss the Procurement and Logistics
Directorate’s Defense Information Technology Contracting Organization’s (PL/DITCO)
organizational context, to including e the current environment’s technical shortfalls and
he goals of the EBM Program; an overview of the EBM Program and concept of
operations (CONOPS); EBM capabilities and requirements; the transition planning; and
esting and evaluation. The appendices provide the high-level architecture
documentation that , which was developed using the Department of Defense (DOD)
Architecture Framework, dated February 9, 2004.

ES-2
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

1
1.1

ORGANIZATIONAL OVERVIEW
PL/DITCO BACKGROUND

PL/DITCO is the procurement arm of the Defense Information Systems Agency (DISA).
PL/DITCO procures global, net-centric telecommunications and commercial iInformation
Technology technology (IT) services and equipment required by DOD cComponents
and other U.S. Government agencies. PL/DITCO employs about 300 contracting
personnel who establish and administer contracts valued at more than $3.0 billion in
financial transactions annually supporting buyers (customers) through innovative
contracting and acquisition logistics. Although PL/DITCO contracts for both IT and
Telecommunications products and services, tTelecom requirements are approximately
about 75 percent% by volume of PL/DITCO’s business. PL/DITCO has a worldwide,
Theater operational presence with offices located atin the following locations::
•
•
•
•
•
•
1.2

Scott Air Force Base, Illinois;
Europe, Sembach Air Base, Germany;
Bahrain, Southwest Asia; and
Pacific, Pearl Harbor, Hawaii;
Elmendorf Air Force Base, Alaska
National Capital Region (NCR), Falls Church, Virginia
PL/DITCO MISSION

The mission of PL/DITCO is as follows:
“Procure global net-centric capabilities and support customers
customers
hrough innovative contracting and acquisition logistics.”
Distributed across five operating locations, PL/DITCO faces the daily challenge of
effectively and efficiently providing IT and telecommunications products and services
hat satisfy DOD (including the nation’s warfighters) as well as other Federal federal
Agency agency requirements. The IT and telecommunications products and services
procured by PL/DITCO procures include networks, systems, point-to-point circuits,
services, equipment and facilities, as well asand computer technology requirements
(e.g., such as: hardware, software, maintenance, and support services). The
preponderance of PL/DITCO’s workload, however, is to establish and administer
contracts for telecommunications products and services on a global basis from
regulated and non--regulated service providerss. Contracting is done performed on
behalf of the DOD and various other federal agencies for lease of telecommunications
services and ancillary equipment at locations within the 48 Contiguouscontinental
United States (CONUS), Hawaii, Alaska, U.S. tTerritories and Possessionspossessions,
and international locations. PL/DITCO maintains the contracting ability to acquire goods
and services of all categories to support its buyers (customers) with one-stop, cradle-tograve acquisition support for IT and telecommunications business solutions. The

1
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

following Ttable 1 identifies lists the types of products and services that bBuyers
procure through PL/DITCO.
Table 1. Products and Services Procured for Buyers
Products and Services
Telecommunication
Pproducts and Sservices

Computer Hhardware and
Ssoftware

Technical Support Services

Non-IT Products and
Services

1.3

Description of PL/DITCO Procurement Services
PL/DITCO provides mechanisms for buyers to acquire a wide variety of
elecommunication products and services. These include, but are no
limited to, , including telecommunications equipment, systems and
networks, support services, and circuits. Circuits maycan include local
elephone service, satellite circuits, and long haul (e.g., circuits such as
asynchronous transfer mode [ATM]).
PL/DITCO provides mechanisms for buyers to acquire computer
hardware and software. Hardware includes , but is not limited to,
personal computers, servers, mainframes, peripherals, printers, and
Internet Protocol Routers (IPR). Software includes licenses for individual
applications as well asand enterprise licenses.

PL/DITCO provides mechanisms for buyers to acquire a variety ofvarious
support services, including: integration engineering, program
management, information assurance (IA), software development, and
modeling analysis.
PL/DITCO provides mechanisms for buyers to acquire non-IT-related
products and services. Historically, these mechanisms have occasionally
included items such as janitorial and lawn care services, office furniture,
carpet, automobiles, conferences, and physical security to name a few.

ENTERPRISE BUSINESS MODERNIZATION OBJECTIVES

In January 2003, the PL/DITCO’s Director and Executive Steering Committee decided
o initiate the EBM Program in order to provide PL/DITCO with tools that better suppor
he organization’s core functional processes.
The goals of the PL/DITCO EBM Program are as followsto:
•

Create a single integrated procurement solution that is uniformly implemented and
readily accessible worldwide.

•

Share consistent data, services, and processes across business functions and
systems applying the tenants and principles of net-centricity.

•

Provide accurate and easily retrievable information for all PL/DITCO contracting
functions and associated external users.

•

Reduce operational costs while increasing procurement efficiency.

The EBM solution will incorporate the mandated federal/DOD e-Business Acquisition
Domain Interim State Procurement Enterprise Systems (ADISPES), and it will solve the
data exchange interoperability gap between these applications to improve information
flow for PL/DITCO’s procurement actions. The integrated solution will provide a single
2
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

source of authoritative data and maximize the exchange of information between these
applications. The objective is an application tool suite that utilizes uses “business
workflow” and net-centric movement of data between applications in order to reduce
manual data entry while increasing data accuracy and integrity of procurement and
financial information.
This COTS solution will address the legacy applications that support the unique
elecommunications contracting mission and integrate the Acquisition Domain Interim
State Procurement Enterprise Systems%. The solution should reduce the number of
unique applications by approximately approximately 75 percent. These reductions will
minimize the number of reconciliation problems that prevail between systems, and will
reduce ongoing operations and maintenance (O&M) costs. The new integrated solution
will use data, triggers, and workflow to process common procurement and order
functions while isolating unique tasks to independent applications. The procuremen
and management benefits that will be realized include reduction in the overall time
required forto training personnel on operations and maintenanceO&M of the new
system, increased data access, increased ease of reporting, increased system
sustainability, and enhanced scalability.
1.4

CURRENT PL/DITCO SYSTEM ENVIRONMENT

To successfully accomplish its procurement mission, PL/DITCO manages, operates,
and and in many cases, has often developed, a group of complex software applications
across a wide range of computing environments, including client/server, mainframe, and
he Web. As is the case with many large enterprises, these applications have evolved
independently over time and do not adhere to a consistent architecture. This
inconsistency in system configuration leads to a number ofnumerous issues:
•

Higher O&M costs of operations and maintenance;

•

User dissatisfaction attributeddue to anthe inability to envisionsee an end-to-end
picture of their the user’s procurement fulfillment process; and

•

Inefficient use of IT resources to support business processes and to accommodate
changes in requirements.

Current systems are a combination of multiple coding languages, platforms, and
processes that have evolved during over the past 30 years. As of 2nd quarter fiscal year
2004, the current systems environment encompasses 11 mainframe applications, 47
client server applications, and 7 Wweb applications running across 68 servers. The
core applications supporting IT products and services contracting are a mix of
independent non--integrated mainframe, client server and Wweb-based applications. I
is important to Nnote, that not all of these applications are present at each PL/DITCO
location. Approximately Roughly sixty-five65 government and contractor full-time
equivalents (FTE)s provide technical support for the systems currently in operation
oday. System changes are increasingly more difficult due toas a result of legacy
coding techniques. In addition, interaction with the system is extremely very
complicated becausesince the terminal screen application lacks any ease of use
3
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

functionality required for efficient navigation. The training requirement to achieve
proficiency using the system exceeds twelve months1 year.
Due to theBecause of a lack of system interoperability, key data elements such as
he(e.g., customer’s (heretofore referred to as “buyers”) requirement number, the
contract number, buyer contact information and vendor contact information) must be
retyped in order for it to exist in the different various applications. This duplicative,
laborious task provides many opportunities for errors and creates athe need to reconcile
system data. Overall, sustaining the status quo provides a short-term solution that does
not assist the organization in meeting its strategic objectives. Although the cost for the
status quo is abnormally high for the provided functionality, the underlying risk is
associated with the lack of an integrated architecture to support a speedy recovery from
a catastrophic application system failure or data loss.

4
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

2

CONCEPT OF OPERATIONS

2.1

OPERATIONAL CONCEPT

PL/DITCO is a “shared services” unit within DISA, which means that it is responsible to
many customers (or buyers) within the DOD andas well as with other federal agencies
worldwide. PL/DITCO provides global contracting to its buyers, which including:e:
•
•
•

Combatant cCommands;
Military dDepartments; and
Defense and other fFederal aAgencies

PL/DITCO provides a number of numerous contract vehicles and other services (e.g.,
contract administration and acquisition planning) to its buyers to facilitate the
procurement of IT and telecommunications needs. PL/DITCO receives funded
elecommunications and IT requirements and needs from its buyers. The organization
leverages its functional alliances with accounting, computing, and policy partners to
generate contracts and orders with IT and telecommunications providers in industry for
he requisite products and services. PL/DITCO supports large contracting projects in
support of the Defense Information System Network (DISN) and programs supporting
DOD’s Global Information Grid (GIG).
Although each PL/DITCO operating location has a different buyer focus, they all work to
achieve the common PL/DITCO mission. PL/DITCO Scott is responsible for the
procuring ement of commercial tTelecommunications and IT products and services
required by DOD agencies and other U.S. government agencies. The scope of
PL/DITCO Scott's procurement responsibility is worldwide in scope. PL/DITCO Scott is
a Defense-Wide Working Capital Fund (DWCF) activity, and therefore recovers its cos
by assessing its buyers a nominal fee for the procurement services provided.
PL/DITCO Europe and its subordinate office in Bahrain are responsible for the
acquisition, and reporting for commercial IT, facilities, equipment, and services for DOD
and other authorized buyers within or between the European-African and Southwes
Asia (SWA) aAreas of rResponsibility (AOR). They execute and manage Indefinite
Delivery/Indefinite Quantity (IDIQ) contracts such as the DISN for their AORs and the
new Europe Enterprise Wireless contract for supporting requirements in Europe and
SWA. PL/DITCO Europe and Bahrain are also DWCF activities. ,
PL/DITCO Pacific and its subordinate office in Alaska are responsible for the
procuringement of communications, facilities, services, and equipment required for the
support of DOD, US Pacific Command (USPACOM), and such other US gGovernmen
agencies as directed by competent authority within or between Pacific AOR. PL/DITCO
Pacific and Alaska are DWCF activities.
PL/DITCO National Capital Region (NCR) plans, awards, and administers contracts for
goods and services that support DISA’'s mission. NCR operates through appropriated
funds, which are authorized and appropriated by Congress. PL/DITCO NCR awards
and administers government-wide acquisition contracts (GWAC) including:
1
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

•
•
•
•
•
•

Defense Information Infrastructure (DII);
Global Command and Control System (GCCS);
Defense Information Systems Network (DISN);
Electronic Commerce/ Electronic Data Interchange (EC/\EDI);
National Communications System (NCS); and
Other government agencies.

Through the EBM Pprogram, PL/DITCO is attempting to trying to improve e buyer
support by thinking “outside of the box” in terms ofregarding how best to provide
innovative, timely, and cost- effective contract support. The EBM solution should
emphasize the use of consistent, streamlined, uniform processes across all PL/DITCO
operating locations. As part of the integrated solution, all of the PL/DITCO sites will
leverage data accessible through a single authoritative source. These processes ,
which will enhance the quality of contract information, and improve process efficiency,
while and reduceing system administration, training costs and eliminate the need to rekey data across operating locations. EBM will employ sophisticated technology
systems to simplify the acquisition process for obtaining a wide range of information
echnologyIT assets, including (e.g., hardware, software, networks, security products,
operations and maintenanceO&M support, telecommunication and information
services). The EBM solution will use contract management techniques to spur more
additional innovation and improve efficiency.
The envisioned concept depicted in the OV-1, Operational Concept Diagram suggests
an integrated environment where buyers, sellers (PL/DITCO), financial managers, and
vendors are creating, accessing, or storing shared data via a universal user interface.
Information will always be stored as structured data when possible and shared via
common interfaces to support operating in a net centric environment.

2
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

Figure 1. OV-1, Operational Concept Diagram Diagram

In general, PL/DITCO receives funded requirements from a wide range of buyers,
providing those buyers with a number ofnumerous contract vehicles, acquisition
planning, and contract administration services. PL/DITCO leverages alliances with the
accounting and finance, computing, and the policy and legal functional areas to procure
he buyer’s requirements establishing contracts, orders, and funds with vendors. Those
vendors then provide the required products and services to the buyers. PL/DITCO
continues to administer the established contracts and orders facilitating payments to the
vendors.
2.2

STAKEHOLDERS /OPERATIONAL NODES

PL/DITCO, a seller, depends on its ongoing relationships with buyers, vendors, and
other key stakeholders to accomplish its daily mission. In commercial industry, typical
vendors include commercial telecommunications companies such as regional
operational bells, local exchange carriers, competitive local exchange carriers, and
other information products and services companies to compete for contracts and orders
o provide telecommunications services and IT products and services to DOD buyers.
3
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

International vendors are commonplace for PL/DITCO as many telecommunications
contracts and orders are awarded and managed by the field offices in Europe and the
Pacific.
To successfully support the procurement process and ensure the application of sound
financial management practices throughout DOD, stakeholders such as DISA’s
Directorate of the Chief Financial Executive (DISA CFE) and DOD’s Defense Finance
and Accounting Service (DFAS) play key roles both in operations and information
exchange. Through accurate and timely information exchange, DFAS ensures vendor
payment in conjunction with the operations of DISA CFE and their supporting
accounting system. DISA CFE in conjunction with PL/DITCO ensure that the
operational revenues and expenses associated with DWCF activities are accounted for
while providing commensurate billing information to the appropriate buyer.
Besides operational revenues and expenses, DISA and PL/DITCO senior managers
require operational information regarding status of buyer requirements, contrac
administration and management information and all in a manner timely enough to
enable effective decision-making. These informational requirements transcend all levels
of management and operations within PL/DITCO in order to best serve our buyers
hroughout the contracting process.
Finally, regulators throughout the Federal Government such as the Federal
Communications Commission and Public Utilities Commission play key roles in affecting
and influencing the administration and management of typical contracts awarded and
administered by PL/DITCO. By changing telecommunications usage rates, tariffs, and
surcharges, these regulators impose unique contract administration activities tha
require robust information systems support to successfully accomplish the PL/DITCO
mission.
A depiction of the interaction between these stakeholders is found in the The OV-2,
Operational Node Connectivity Diagram, illustrates the interaction between the
stakeholders diagram below.

2.3

BUSINESS PROCESS DESCRIPTION

PL/DITCO, as with most federal contracting organizations, follows the Federal
Acquisition Regulation (FAR) and its authorized supplements as the operational policy
and guiding regulation for conducting contracting operations. In aAdditionally,
PL/DITCO is compliant with both the DISA and DoD BMMP Acquisition Domain EAs. In
general, Tthe PL/DITCO business process will follow the Acquisition Domain’s “Conduc
Sourcing” business process model shown in Ffigure 2 below. It is important to Nnote
hat the “Assess Business Plan Acquisition Resources” process is not encompassed
within the EBM program.

4
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

Figure 2. Acquisition Domain General Conduct Sourcing Business Process Model
Assess
Business
Plan
Acquisition
Resources
All budgeting and
planning
activities which
generate
acquisition
requirements

Manage
Requiremen

Validating the
acquisition
requirement and
obtaining apportioned
funds.

Develop
Acquisition
Strategy

Execute
Acquisition
Strategy

Manage
Procuremen

Planning how to
source the
requirement, including
potential providers,
solicitation strategies
and selection criteria

Soliciting proposals,
establishing sourcing
vehicles and
generating requisitions
with committed funds.

Creating orders with
obligated funds,
monitoring receipt of
orders and closing ou
contracts.

IT procurement requirements are submitted to PL/DITCO, which works with the buyer to
develop the acquisition strategy. Upon receipt of a completed acquisition package from
he buyer, the seller (e.g., PL/DITCO) Stransforms the requirement into a solicitation,
which is offered to potential vendors. Vendors may have questions on solicitations,
which are answered by the seller and can result in the seller issuing solicitation
amendments. Vendors respond to solicitations with proposals. Vendor proposals are
evaluated and may result in proposal revisions. Upon completion of proposal
evaluations, the seller makes an award obligating funds and then administers the
contract through close out. During administration, buyers may initiate orders and/or
modifications against the contract. Also during administration, the vendor submits
invoices to the buyer and accounting and finance, buyers issue acceptance notices to
accounting and finance and accounting and finance pays the vendor and bills the
customer.
Similar to IT contracting, the procurement of telecommunications services will continue
o rely on the receipt of buyer requirements in a single standardized format, which are
ransformed into solicitations and which posted as potential opportunities for vendors.
These solicitations include a wide spectrum of long-haul telecomm services: such as:
business lines and dial tone services, local area access, Intrastate intrastate and
iInterstate point-to-point services, switched services, domestic and international long
distance services, 800 sServices, fFrame rRelay sServices, Asynchronous
asynchronous tTransfer mMode (ATM) services, pPacket sSwitched dData sServices,
video services, and Integrated Switched Digital Network (ISDN) services. Analog
services are typically 3-kKHhz voice grade circuits, while whereas digital services range
from 9.6 kilobytes per second (KBSkbs) (narrowband) to OC-N (wideband) circuits.
However, the uniqueness of telecom procurement for DOD and other federal agencies
is demonstrated in several examples. First, telecom is a heavily regulated industry.
Existing contracts can be unilaterally modified by the vendor by simply submitting a tariff
change to the FCC. Once approved, DITCO must discover which of 100,000 contracts
is affected by that change and modify those contracts accordingly (as well as the
payable records). Often, this involves adjusting contracts for bill periods that have
5
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

already cleared, and sometimes in previous fiscal years. Second, the volume of running
contracts (and invoices) makes positive receipt and acceptance for every invoice
impossible. Further, DISA rules governing communications (DISAC 310-130-1) requires
a disconnect order be issued before a service is disconnected, even if the service life on
he order is expired. These, and many other challenges specific to telecom, make this
process unique and very challenging.
The OV-6c Operational Event /Trace Description provides a A more detailed
presentation of the PL/DITCO business process for both IT and Telecom contracting is
located in Appendix D.
2.4

EBM SOLUTION EXTERNAL INTERFACES

The EBM solution will replace many of the current PL/DITCO applications and must
interface with the BMMP ADISPES as well as a number ofand numerous other external
applications. Based on an assessment of similar telecommunications industry systems,
and on the similarity of the PL/DITCO requirements with the typical telecommunications
Operational Support System (OSS) functionality, five components or functional areas of
he EBM solution are identified as:
•
•
•
•
•

Buyer Management;
Data and Reporting Managemen
Financial Managemen
Order Managemen
Workflow and Document Management; and

These nine functional areas may have one or more external interfaces with BMMP
ADISPES and/or external applications. The Data and Reporting Management and
Reporting component of the system must establish many interfaces with external and
BMMP ADISPES systems. According to DOD policy, the interim state defines the
solution set that each mMilitary Department department and dDefense aAgency will use
o procure goods and services and conduct other procurement activities. The EBM
solution will likely need to interface with 9 of the 13 ADISPES systems and be able to
readily access the remaining 4 systems if necessary. In addition to the 13 ADISPES
systems, there are two other external systems—, Electronic Document Access (EDA),
and Excluded Parties Listing System (EPLS)— that are noteworthy for the EBM
solution. Table 21, which below lists the external applications, provides a description
ofdescribes the system functionality and of each system and summarizes the
application that each of the 15 systems is expected to have on EBM.

6
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

Table 12. EBM External System Application
## DOD ADISPES
System
Central Contractor
Registration (CCR)

Primary Procurement and
Procurement-Related Capability
The primary vendor registration database for the
U.S. Federal Government. The CCR collects,
validates, stores, and disseminates data in suppor
of agency acquisition missions. CBoth current and
potential government vendors are required to
register in CCR in order to be awarded contracts by
he government. Vendors are required to complete
a one-time registration to provide basic information
relevant to procurement and financial transactions.
Vendors must update or renew their registration
annually to maintain active status. CCR validates
he vendor’s information and electronically shares
he secure and encrypted data with the federal
agencies’ finance offices to facilitate paperless
payments through electronic funds transfer (EFT).
In aAdditionally, CCR shares the data with
government procurement and electronic business
systems.

Application to PL/DITCO
EBM Ssolution
The PL/DITCO EBM
solution will accept data
from CCR to transmit data
by accessing information
from the comprehensive
database on all registered
vendors.

Online
Representatives
and Certifications
Applications
(ORCA)

Vendor submission of representations and
certifications. ORCA is a fFederal--wide system tha
replaces many of the provisions placed in Section K
of every solicitation with a centralized on-line
application. Using this application, where vendors
can provide that information once and update it as
necessary. and Ccontracting officers also can
review the information provided. The , the FAR is
being updated to reflect this process.
Government office registration. FedReg collects
information about federal government offices tha
act as trading partners, using bBusiness pPartner
nNetwork nNumbers/tTrading pPartner nNumbers
as unique identifiers for individual federal locations.
FedReg then sends this data to the exchange
system, so that information about each participan
can be included with each transaction.

The PL/DITCO EBM
solution will exchange
information with ORCA
related to vendor
representations and
certifications.

Posting of business opportunities.
http://www.fedbizopps.gov/ is the single
Government government point-of-entry (GPE) for
federal government procurement opportunities over
exceeding $25,000. Government buyers are able
ocan publicize their business opportunities by
posting information directly to FedBizOpps via the
Internet. Through a single portal, FedBizOpps
commercial vendors seeking federal markets for
heir products and services can search, monitor, and
retrieve opportunities solicited by the entire federal
contracting community.

The PL/DITCO EBM
solution will transmit data to
FedBizOpps to provide a
seamless capability to pos
solicitations online.

Federal
Registration
(FedReg)

Federal Business
Opportunities,
FedBizOpps, (FBO)

7
FINAL DRAFTv1.0

The PL/DITCO EBM
solution will not be
integrated with FedReg, bu
will be accessible as a
lookup system serving as a
primary source for federal
rading partners.

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT
## DOD ADISPES
System
Federal Technical
Data Solutions
(FedTeDS)

IntergGovernmental
Transactions
Exchange (IGTE)

Federal
Procurement Data
System-Nex
Generation (FPDSNG)

Past Performance
Information
Managemen
System (PPIMS) /
Past Performance
Information
Retrieval System
(PPIRS)

Primary Procurement and
Procurement-Related Capability
Online posting of technical documents supporting
procurement. FedTeDS is a Wweb application
developed under eE-Government's Integrated
Acquisition Environment. FedTeDS enables the
distribution and dissemination of Sensitive Bu
Unclassified (SBU) acquisition material related to
solicitations found on FedBizOpps.gov. FedTeDS is
designed to safeguard sensitive acquisition- related
information during the solicitation phase of the
procurement cycle.
Processing of inter-governmental transactions.
OMB and the Integrated Acquisition Environmen
(IAE) team established basic requirements for
processing and recording intragovernmental
ransactions for all agencies. An IGTE production
pilot for rent and reimbursable IT services
ransactions began in October 2003. All
departments and major agencies are expected to
process rent and IT services transactions over
exceeding $100,000K through the IGTE by July
2004. It is envisioned that all intragovernmental
ransactions (excluding those paid via a credit card)
will eventually be fed through the IGTE for
processing and tracking.
Reporting of contract award information. The
central repository of statistical information on federal
contracting. It contains detailed information on
contract actions of more than $25,000 and summary
data on procurements of less that $25,000. The new
system, FPDS-NG, will integrate with every
government procurement system in real time. This
electronic interoperability will allow contracting
agencies to reduce or eliminate some of the manual
processes required to collect and summarize
information about millions of smaller procurements.
Retrieval of past performance report cards. A
Wweb-enabled, government-wide application tha
provides timely and pertinent contractor pas
performance information to the federal acquisition
community for use in making source selection
decisions. PPIRS assists federal acquisition officials
in making source selections by serving as the single
source for contractor past performance data.
Confidence in a prospective contractor's ability to
satisfactorily perform contract requirements is an
important factor in making best- value decisions in
he acquisition of goods and services.

8
FINAL DRAFTv1.0

Application to PL/DITCO
EBM Ssolution
The PL/DITCO EBM
solution will transmi
information to FedTeDS as
required to post technical
information supporting a
solicitation also posted on
FedBizOpps.

The PL/DITCO EBM
solution will accept data
from IGTE to assist with the
processing of intergovernmental financial
ransactions both in the
certification of funding
availability and in
processing AccountsPayable transactions. IGTE
will when complete, suppor
he MIPR process.
The PL/DITCO EBM
solution will transmi
information to FPDS-NG to
enable seamless reporting
of required statistical
information. FPDS-NG will
be the authoritative
reporting source for
reporting of contract award
information.
The PL/DITCO EBM
solution will transmit data to
PPIMS/PPIRS.

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT
## DOD ADISPES
System
Wage
Determinations
On-Line (WDOL)

Primary Procurement and
Procurement-Related Capability
Receiving wage determination data. WDOL is a
fFederal--wide, Wweb-enabled system that will
eliminate the longstanding paper process of
requesting wage determinations from the
Department of Labor using the Standard Form 98
(which could requiretake months) by an electronic
retrieval of wage determinations accomplished with
one Internet session.

Application to PL/DITCO
EBM Ssolution
The PL/DITCO EBM
solution will not be
integrated with WDOL, bu
will be accessible as a
lookup system for wage
determination information.

Interagency
Contract Directory
(ICD)

Reporting of Interagency contracting vehicles. ICD
is a searchable directory of government wide
acquisition contracts (GWACs), multi--agency
contracts, Federal Supply Schedule (FSS)
contracts, or any other procurement instrumen
intended for use by multiple agencies, including
Blanket Purchase Agreements (BPAs) agains
Federal Supply ScheduleFSS contracts.
Contract writing and administration. The system
supports the on-going data exchange between SPS
commercially known as PD2, and external systems
hat maintain functional communities such as
Finance and Logistics. Essentially, SPS moves data
created by other applications, such as requisition
data, for loading into PD2 or it moves data created
by PD2, such as contract award data, for loading into
other dependent databases. The SPS extracts data
from the PD2 database to build outgoing interface
files and inserts this data into the PD2 database
received via incoming interface files.
Processing of invoices and receiving reports.
Provides the baseline technology for governmen
vendors and authorized DOD personnel to
generate, capture, and process receipt and
payment-related documentation, via interactive
Web-based applications. Authorized agency users
are notified of pending actions and are presented
with a collection of documents required to process
he contracting or financial action.
Electronic ordering under non-GSA schedule
vehicles. DOD EMALL is the single entry point for
DOD and other fFederal buyers to find and acquire
off-the-shelf, finished good items from the
commercial marketplace.

The PL/DITCO EBM
solution will not be
integrated with ICD, but will
be accessible as an online
look-up system for
acquisition contrac
information.

Standard
Procuremen
System (SPS)Procuremen
Desktop Defense
(PD2)

Wide Area
Workflow – Receip
and Acceptance
(WAWF-RA)

DOD Electronic
Mall (DOD EMALL)

9
FINAL DRAFTv1.0

The PL/DITCO EBM
solution will exchange data
with the SPS PD2 contractwriting tool. The EBM
solution will address
elecom contracts and
orders.

The PL/DITCO EBM
solution will exchange
contractual data with
WAWF-RA for the receip
and routing of invoices tha
result from “standard”
(non--telecom IQO)
contracting.
The PL/DITCO EBM
solution will not be
integrated into DOD
EMALL, but will be
accessible online as a
principal means to procure
certain finished goods.

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

Other External Systems:
Additional
Acquisition
Domain Endorsed
System
Electronic
Document Access
(EDA)

Excluded Parties
Listing System
(EPLS)

Primary Procurement and Procurement-Related
Capability

Application to PL/DITCO
EBM Solution

EDA provides a single, read-only "electronic file
cabinet" that can be accessed by any authorized
user, both within DOD and in the vendor community.
Vendors may be authorized to view only contrac
documents that match their validated Data Universal
Numbering System (DUNS) or commercial and
government entity (CAGE) codes. The system
provides storage and retrieval of post-award
contracts, contract modifications, personal property
and freight government bills of lading (GBLs),
vouchers, Contract Deficiency Reports (1716s),
Summaries of Voucher Line Data (110 Reports),
Materiel Acceptance and Accounts Payable Reports
(MAAPRS), and Army direct vendor deliveries
(DVDs) in a compressed text format running on
DOD's private network. EDA capitalizes on
communication networks and commercial tools tha
are widely used today. EDA provides paymen
echnicians at the Defense Finance and Accounting
Service (DFAS), DOD contract officers, procuremen
officers, and transportation technicians with the
ability to view and process documents without paper
copies. Vendors have view-only capability of their
contract documents only.

The PL/DITCO EBM
solution will transmi
information to EDA for filing
contracts.

The electronic version of the Listing of Parties
Excluded from Federal Procurement and Non-procurement Programs (Lists), which identifies
hose parties excluded throughout the U.S.
Government (unless otherwise noted) from
receiving fFederal contracts or certain subcontracts
and from certain types of fFederal financial and nonfinancial assistance and benefits.

The PL/DITCO EBM
solution will exchange data
with EPLS related to
excluded parties.

The Figure 3, identifies the system interfacegraphic below depictss necessary between
he PL/DITCO EBM solutiion and key external systems in the tTo-bBe environment.
The EBM solution is shown in green, ADISPES systems s are shown in orange, and
other interfacing systems are shown in yellow. During the Manage Requirements
phase, requirements and telecom rates are received from external systems, via e-mail
or manually and acted upon to include certifying the availability of funds. During the
Develop Acquisition Strategy phase, the solution shall validate buyer and vendor
information with ADISPES systems. The solution shall engage the Standard
Procurement System (SPS) system to write a contract. During the Execute Acquisition
Strategy phase, the solution should post the solicitations to FedBizOpps and facilitate
he , receipt and evaluation of proposals. In addition, the solution should facilitate the
10
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

award of a contract to the winning vendor continuing to update the authoritative contract
file in the Workflow and Document Management system. During the Manage
Procurement phase, the solution monitors the receipt of orders, generates accounts
payables and receivables, and supports the reporting requirements of both ADISPES
and telecom systems.
Figure 3. To-Be SV-1, System Interface Description
Manage Requirements

Develop Acquisition Strategy

Execute Acquisition Strategy

Manage Procurement

Telecom Rates

AQ Domain Interim State Systems
External Systems

EDA

ORCA
## EPLS

TCOSS

Contract Data

Fin Data

SPS PD2

PPIMS/PPIRS
PL/DITCO EBM

FBO

PAWS

Invoices

IGTE

Entitlement

Telecom Data

Telecom Inventory

FPDS-NG
Invoices

FedTeDS

Solicitations

Acquisition Packages

CCR
Notifications

DDOE

Funding Availability

TIMS

Responses
& Quotes

Buyer & Vendor Data

WWOLS-R

Buyer Management

Contract Data

Financial Management
Delivery Orders

Order Management

Requirements

WAWF-RA

Business Partner Network

FAMIS
DMS Email

11
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

3

REQUIREMENTS

This section of the document outlines the capability areas within which the requirements
of the Enterprise Business ModernizationEBM Program align. High-level functional
requirements can be found in the SV-4, Systems Functionality Description, and desired
capabilities are located in the Fit Gap Matrix located in the Appendices.
3.1

SYSTEM FUNCTIONALITY

The capabilities and detailed system requirements are classified into the following
functional categories:
•

Buyer Management— – Outlines the buyer’s needs of the buyer (customer) in
accessing EBM, which includinges but is not limited to entering and managing buyer
information. Buyers also have the ability tocan access a limited amount of
information, including submitted proposals and some online reports.

•

Data and& Reporting Management— – Outlines the behaviors and requirements
needed to enter, store, manipulate, and retrieve information. This includes, including
agging, warehousing, mining, and distributing on of data. Ensures easy discovery
and access of structured and unstructured data. Information can be co-located in a
single repository or distributed across accessible databases. Includes the standards
and principles of reporting.

•

Financial Management— – Outlines the tasks and requirements for financial
operations (e.g., such as general ledger, accounts payable, accounts receivable,
payment processing, and administration of invoices), etc.

•

Infrastructure— – Outlines the technology foundation, standards, and
considerations that must be taken into account when developing EBM. Includes the
basic facilities, services, and installations needed for the functional operations.

•

Interfaces— – Outlines the specific needs related to system interfaces and
information flows between both the EBM and the, internal and external sources as
appropriate.

•

Order Management— – Outlines the ability to enter information related to a
purchase, including requirements, funding allocation, purchase requests, inquiry and
order (IQO), IT and telecommunications orders. This module also enables the buyer
and vendor to track requirement status.

•

Security Management— – Outlines the considerations and fundamentals
necessary forto ensuringe secure access to online information and information
exchanges. This includes, including the application program security,; roles- based
access to information, and object- oriented database access controls.

•

System Administration— – Outlines the organizational and managerial functions
and requirements that are necessary for overall software governance. Includes,
including functions needed to configure user access to the system.
1
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

•

Workflow and& Document Management— – Outlines the tasks and requirements
hat are needed for end-to-end process and document management, even
detection, and response. Enables the monitoring and tracking of content as it moves
hrough select business processes. Provides ready access to organized
information so that decisions can be made based on the latest data.

2
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

4

TRANSITION PLAN

The EBM contractor shall develop a detailed EBM Transition Plan that demonstrates
how the solution will transition current system functionality to the new EBM
environment. The Transition Plan shall establish a phased approach for providing the
functionality that will achieve the below stated factors in a lower risk approach.
PL/DITCO will leverage its existing requirements management process during the
implementation of the EBM system.
It is desired that any discovery period necessary be accomplished within 3 months
following award. The transition plan will be structured accordingly with targeted IOC in
12 months and FOC in 24 months following award. The contractor will include a
ransition plan that at a minimum cites the milestones identified in Table 5 below.
Table 3. EBM High-level Transition Plan
Milestone
Acceptance of Final
Design

Sub Activities
Discovery
Review Preliminary Design
Revise Program Plan
Assess External Interface Requirements
Establish Phased Approach for Functionality
Review System Requirements
Validate EBM Design
Review Final or Critical Design
Revise TEMP Master Plan

Completion Date

Initial Operating
Capability

Integrate
Test and Revise

360 DACA

Full Operating
Capability

Integrate
Test and Revise

720 DACA

90 DACA

The current PL/DITCO business and technology environment presents limitations to
continued effective telecom and IT contracting. In addressing those current limitations,
PL/DITCO established certain criteria that shall be considered in developing a lower
risk, phased approach to transitioning to EBM. EBM development and implementation
shall follow a phased approach that accommodates higher priority requirements firs
while assessing the impact on external stakeholders (those outside of PL/DITCO), and
fulfilling more easily achieved requirements.
Contracting –
•

Establish a graphical user interface solution for the receipt of buyer requirements

•

Institute a solution for the electronic receipt of telecom transactions

1
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

•

Establish interfaces with two key telecom requirements input systems: Worldwide
Online System–Replacement (WWOLS-R) and Tactical Information Managemen
System (TIMS)

•

Create an interface to issue solicitations that populate FedBizOpps

•

Establish an interface to populate PD2

•

Provide a capability to issue contracts and orders from PD2

•

Create the ability to issue an modification to an order

•

Institute the capability to track requirements and obligations against a contract

•

Establish the capability to identify buyer acceptance and receipt of goods and/or
services

Financial Management –
•

Establish the capability to record buyer information associated with funding
authorization

•

Develop and demonstrate a working interface with a JFMIP compliant general ledger
system (currently Financial Accounting and Management Information SystemFAMIS)

•

Establish an interface to transfer buyer’s financial information to the general ledger

•

Institute the capability to request and receive certification for funds availability

•

Establish an interface to transfer financial transactions for obligation to the general
ledger

•

Establish an interface to transfer modifications of financial transactions for
obligations to the general ledger

Data and Reporting –
•

Develop and implement a data migration strategy that accounts for 100,000 plus
active records with access to at least 6 years 3 months of historical data from the
point of contract closeou

•

Establish a capability to retrieve logs and reconcile transmissions for each
information exchange between system boundaries

•

Provide the capability to access financial information associate with the contracting
action

•

Establish a capability to access all contracting information associated with a
requiremen

•

Provide the capability to perform ad-hoc reporting on any data stored in the
database
2
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

•

Provide the ability to run a subset of standard reports

Technical –
•

Provide the capability to administer user profiles for access and authority to system
functions

•

Ensure that the system is capable of running on DISANet

•

Establish the capability to restrict user access to information based on roles and
profiles in the system

•

Establish a security capability that protects unclassified but sensitive (UBS)
information through permissions-based access controls

•

Establish open interfaces with external stakeholders that support the principles of
he DOD’s Net-Centric Data Strategy.

To achieve initial operating capability (IOC), the system shall meet the above-specified
critical factors in the areas of contracting, financial management, data and reporting,
and technical. In addition, current operational data must be migrated to the EBM
system to maintain continuity of contracting operations. As with any system
implementation, security is a primary concern to protect the data’s integrity, limiting
access to those authorized users based on their roles, while not inhibiting productivity or
scalability.

3
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

5

TEST AND EVALUATION

The EBM contractor(s) shall will perform and provide configuration testing as needed.
Configuration testing will be consistent with the objectives of the EBM Program and the
echnical risk adherent to the proposed solution and implementation plan. EBM is
required to pass a Government government aAcceptance tTest, which consists of
verifying and validating that the proposed solution satisfies the contract requirements.
The gGovernment aAcceptance Test test includes , but is not limited to, an evaluation of
proposed solution against the CRD, an iInstallation tTest, Information information
aAssurance tTest, a sSecurity tTest and eEvaluation (ST&E), and an eEnd-to-eEnd
System system iIntegration tTest.
The DISA Joint Interoperability Test Center (JITC) will perform iInteroperability tTesting
on the EBM solution. EBM must receive an iInteroperability tTest cCertification and
pass an Operational operational aAssessment tTest before implementation. The EBM
contractor(s) shall will provide thethe Ggovernment copies copies of all test scenarios
and test reports and /results that are associated with the selected solution at no
additional cost to the Government.
The Test and Evaluation Master Plan (TEMP)P shall will provide a road map for
integrated EBM solution development and testing, to includinge the plans, schedules,
and resource requirements necessary to for accomplishing testing and evaluation. The
TEMP pPlan shall will be consistent with and supportive of the overall EBM concept of
operationsCONOPS, and will provide information about risk assessment and mitigation.
The TEMPP shall will identify empirical data to be used for validating each phase of
system delivery and evaluating technical performance and system capabilities agains
he critical factors and desired system capabilities- KPPs of this CRD. In addition, the
TEMP shall detailed resources needed to support the system deployment phases.
The TEMP must include test events, scenario descriptions and resources to fully tes
requirements. Testing resource requirements will outline any tester or /user preparation
needed and simulated data that align with use cases and test limitations that impact the
system evaluation for each system deployment phase.
The TEMP will include iInformation aAssurance (IA) tTest and eEvaluation, which will be
conducted based on tailored DOD Information Technology Security Certification and
Accreditation Process (DITSCAP) (DOD 5200.40) to meet the needs of the nNetcCentric Web sServices pPrinciples and aArchitecture. A tailored Service Security
Authorization Agreement (SSAA) will be developed and a tType aAccreditation will be
sought from the dDesignated aApproving aAuthority (DAA). Following security TEMP
results, and positive recommendation to the DAA, an Authority tTo Operate (ATO) or
Interim ATO (IATO) will be issued.
The EBM solution provider(s) shall be responsible for corrections required due to as a
result of failure to successfully pass the gGovernment aAcceptance tTesting,
iInteroperability tTest, and Operational operational aAssessment tTest at no additional
cost to the Government.
1
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

2
FINAL DRAFTv1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX A—OV-1 OPERATIONAL CONCEPT GRAPHIC
The Operational Concept Graphic (OV-1) provides the high-level notional graphic
depiction of the Enterprise Business Modernization (EBM) architecture. This graphic
highlights the mission, domain, scope, intent, and general business processes
encompassed within EBM. In addition, this graphic identifies key organizations and
interactions.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX B—OV-2 OPERATIONAL NODE CONNECTIVITY DIAGRAM
The Operational Node Connectivity Description (OV-2) provides the operational nodes,
connectivity, and information exchange need-lines between nodes. The Defense
Information Technology Contracting Organization (DITCO) to-be OV-2 contains six
nodes, which display the following:
•

Buyer who has funded requirements for information technology (IT) and telecom
products and services.

•

Seller (or DITCO contracting specialist) who processes the buyer’s funded
requirement to establish a contract to fulfill the buyer’s IT and/or telecom needs.

•

Vendor who fulfills the buyer’s IT or telecom requirements with a product or service.

•

DITCO Financial Manager who manages the working capital fund (WCF) to
reconcile vendor invoices with buyer funds.

•

Accounting and Finance Manager who pays vendors from buyer accounts.

•

External Agencies that receive reports on ongoing DITCO operations.

These nodes are connected by multiple need-lines. These need-lines display the type
of information that is being exchanged by the operational nodes. The following are the
need-lines expressed in the DITCO to-be OV-2:
From Buyer to Seller:
•

Funding Information

•

Receipt and Acceptance

From Buyer to Seller (for IT):
•

Acquisition Packages

From Buyer to Seller (for Telecom):
•

Telecommunication Service Requests (TSR’s)

•

Telecommunication Service Orders (TSO’s)

From Seller to Buyer:
•

Procurement Status Updates
1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

From Vendor to Seller:
•

Responses to RFIs and Solicitations

•

Contract/Order Acceptance

•

Completion Notice

From Vendor to Seller (for Telecom):
•

Order Receipt

•

Jeopardy Notice

From Seller to Vendor:
•

RFI’s and Solicitations

•

Contract/Order

From Seller to External Organizations:
•

Contract Reporting

•

Past Performance

From Seller to External Organizations (for Telecom):
•

Rates: Tariffs and Taxes

From Accounting and Finance to Vendor:
•

Payment

From Vendor to Accounting and Finance:
•

Invoice

2
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

From Seller to Financial Manager:
•
•

Funds Available Certification Request
Billing Actions (TSO)

From Seller to Financial Manager (IT):
•

Buyer Funding Acceptance Request

From Financial Manager to Seller:
•
•

Funds Available Certification Response
Billing Information

From Financial Manager to Seller (IT):
•

Buyer Funding Acceptance Response

From Financial Manager to Buyer:
•

Buyer Billing Detail

•

Funding Acceptance Response

From Buyer to Financial Manager:
•

Funding Information

From Accounting and Finance to Buyer:
•

Buyer Bill

From Buyer to Accounting and Finance:
•
•

Receipt and Acceptance (Payment Process)
Buyer Remittance

3
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

From Seller to Accounting and Finance:
•
•

Contract/Order Information
Billing Details for AR

From Vendor to Buyer:
•

Invoice

4
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX C—OV-3 INFORMATION EXCHANGE MATRIX
The OV-3, Information Exchange Matrix, is a tabular product that provides details on the
information flows defined in the OV-2, Operational Node Connectivity Diagram. The OV3 serves five major purposes:
•

To identify characteristics and performance required for information exchanges,
particularly those that span organizational or system boundaries

•

To support the identification of systems interfaces and development of system
performance requirements

•

To link the information flows of the OV-5 to the OV-7 Logical Data Model so that the
wo models may support and validate each other

•

To capture demands made on communications links and support development of
communications system requirements

•

To support information assurance (IA) planning

Following are definitions of the column headings used in the Defense Information
Technology Contracting Organization (DITCO) information exchange matrix.
Information Exchange
Matrix Heading
Need-line Identifier
Detailed Information
Exchange Title
Information Exchange
Description
Information Exchange
Packet Size (maximum
kilobytes)
Information Exchange
Operational/Business
Process Activity
Information Exchange
Producer
Information Exchange
Consumer(s)
Transaction Type
Transaction Forma
Triggering Even

Definition
Reference title from the OV-2 that identifies the need-line that carries the
information exchange.
Reference title that identifies the information exchange—usually based on
relevant operational/business context and should be unique for the
architecture.
Brief narrative description of the information exchange that captures the
content, operational/business context, and purpose of the exchange.
The maximum size, in kilobytes, of electronic information exchange packets.
(Typically information exchange packets vary in size, so the maximum size
should be used to enhance future system performance.) If the information
exchange is not electronic, state size in number of letter-sized sheets of paper.
The business process activity that produces the information.
The organizations or users that produce or initiate the information exchange.
The organizations or users that are authorized to consume or receive the
information exchange.
Description of the type of transaction, e.g., file transfer, data transfer, recurring,
notification.
The electronic format of the transaction, e.g., MIME message, SOAP message,
IP.
Brief description of the events (either human- or system-driven) that triggers or
initiates the information exchange.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT
Information Exchange
Matrix Heading
Periodicity

Access Control
Availability
Confidentiality
Dissemination
Control/Releasability

Definition
How often the information exchange occurs; may be an average or a wors
case estimate and may include conditions based on the operational/business
process; may include the frequency of the automated system follow-up and
racking actions.
The class of mechanisms used to ensure that only those authorized can
access the information.
The relative level of effort required to be expended to ensure that the system
data can be accessed.
The kind of protection required to protect the information from unintended
disclosure, e.g., FOUO, proprietary.
The kind of restrictions on receivers of the information based on the sensitivity
or confidentiality of the information.

2
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX D—OV-5 OPERATIONAL ACTIVITY MODEL
The OV-5 is a table that defines the steps in a business process and may include
definitions of the sequence and dependencies among steps, the information that flows
between them, or both. Most OV-5s represent an iterative decomposition of activity
within a process to a number of levels of indenture appropriate to the specific objectives
of the model. The OV-5 is the primary product of mission analysis/process
improvement and was produced by the process owners, which are the Procurement and
Logistics/Defense Information Technology Contracting Organization (PL/DITCO)
integrated project teams (IPT).
The OV-5 is a key product for describing capabilities and relating capabilities to mission
accomplishment. The PL/DITCO OV-5 is used in conjunction with a process flow model
(the Ov-6c) to describe the sequence and other attributes (e.g., timing) of the activities.
The PL/DITCO process flow model further captures precedence and causality relations
between activities as well as information flows. The PL/DITCO activity model is
compliant with both the Defense Information Systems Agency (DISA) and the Business
Management Modernization Program (BMMP) (Acquisition Domain) activity models
providing a framework to show how the PL/DITCO process relates to other associated
activities.
The PL/DITCO OV-5 is divided into the four phases of the contract life cycle from the
BMMP “Conduct Sourcing” model:
•
•
•
•

Manage Requirements
Develop Acquisition Strategy
Execute Acquisition Strategy
Manage Procurement.

The lower level activities also follow the Conduct Sourcing model but show many of the
unique activities performed by PL/DITCO contracting specialists supporting
elecommunications requirements. A more detailed description of the activity model is
found with the OV-6c, Operational Event/Trace Description.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX E—OV-6C OPERATIONAL EVENT/TRACE DESCRIPTION
This appendix describes the Telecommunications and Information Technology (IT)
Contracting Process, which contracts for telecommunications & IT services and
products with commercial providers in support of the Department of Defense (DOD)
mission and a wide variety of other federal government customers. This document is
organized by the four functional areas that compose the contracting process. The fifth
section is dedicated to describing the process by which buyers may procure services via
he Remote Ordering Process.
I. Requirements Managemen
II. Acquisition Strategy Developmen
III. Acquisition Strategy Execution
IV. Procurement Managemen
V. Remote Ordering Process
Section I. Requirements Managemen
1.1. Discuss Need
This activity involves receiving and reviewing the buyer’s requirement to verify its
accuracy and completeness.
1.2. Assist Buyer with Market Research (if applicable)
This activity involves research of acquisition policy, guidance, industry capability, and
procedures to guide development of the appropriate acquisition strategy to meet the
buyer’s requirements.
1.3. Provide Acquisition Recommendation (if applicable)
This activity provides the buyer with a recommended acquisition strategy given the
buyer’s unique requirement(s). Additional activities include responding to buyer
requests for assistance by providing technical acquisition support to assist in the
development of buyer technical requirements.
1.4. Submit Acquisition Package
This activity involves the completed acquisition package being submitted by the buyer.
1.5. Review and Process Requirements/Acquisition Package
This activity receives and analyzes requirements for technical factors and other related
issues. This activity also determines if the acquisition package contains all required
documents.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

1.5.a. Establish Funding Information (as needed)
This activity establishes a buyer and the related funding (as necessary). This data is
accessed to verify that an account is in place for received requirements.
1.5.b. Update General Ledger (GL) (as needed)
This activity records accounting transactions in the General Ledger, committing funds,
and recording the commitment in appropriate budgetary accounts. This involves
recording the commitment and budget information.
Section II. Acquisition Strategy Developmen
Is Existing Contract In Place?
This activity involves the determination of whether a contract is currently in place tha
may be utilized to meet the buyer’s requirement.
Is Competition Required?
If an existing contract is in place, this activity involves determining whether competition
is required. If competition is not required, the process may skip the steps associated
with preparing and issuing a solicitation (and go directly to ‘Issue Contract Action’ (3.5)).
If competition is required, the process of developing a solicitation must be followed.
2.1. Prepare Solicitation
This activity includes all tasks required in the preparation of the solicitation. Some
examples include: determination of contract type, determination/coordination of socioeconomic programs, development of the solicitation notice, creation of the source list,
preparation of determinations and findings, and preparation of the solicitation.
Is Review Required?
This activity involves determining whether Policy & Legal must review the solicitation
before issuance.
2.2. Perform Policy and Legal Review
This activity, performed by Policy and Legal, provides acquisition legal advice and
guidance in response to requests for legal action. Policy and Legal assists in the
formulation of all procurement policy initiatives and serve as legal advisors in formal
source selections.
2.3. Issue Solicitation
This activity involves preparing and releasing the final solicitation.
2
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

2.4. Review Solicitation
This activity involves a review period during which the vendor examines the solicitation
o formulate a response.
2.5. Submit Questions (if applicable)
This activity describes the vendor’s questions regarding the solicitation.
2.6. Review Questions and Answer
This activity describes the process of providing clarification to vendor questions and
determining if inquiry modifications are required.
Pre-Award Protest?
This activity involves determining whether there is a pre-award protest. If there is a
protest, it must be processed before the contracting process may continue.
2.7. Process Pre-Award Protests
This activity reviews the protest document for understanding of its basis and content for
pre-award.
2.8. Submit Response
This activity involves the submittal of a complete response to a solicitation.
Section III. Acquisition Strategy Execution
3.1. Evaluate Response
This activity performs the technical, contractual, and cost/price evaluation of the quote
including preparing for and conducting evaluation panels and meetings.
3.2. Provide Evaluation Results/Select Awardee
This activity provides the evaluation results of the quote received from a vendor and
related recommendations for award to the CO for review. This activity also involves the
selection of the awardee(s).
3.3. Prepare Contract/Obtain Award Approvals
This activity prepares the contractual vehicle for further processing. Elements included
may be Legal Review, Compliance Review, documenting the file with the evaluation
results, or determining fair and reasonable pricing.
3
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

3.3.a. Perform Funds Certification
This activity provides assurance that funding is currently available in DWCF and has
supporting buyer-funded requirements.
3.4. Notify External Stakeholders
This activity provides notification to all concerned parties as necessary, to include:
Regrets to unsuccessful vendors, notification to the vendor of a contract award, and
Congressional notification (as necessary).
3.5. Issue Contract Action
This activity encompasses a number of actions required subsequent to the issuance of
a contract, such as: Providing debriefings for unsuccessful and successful vendors in
large or complex contracts when required, processing of protests, processing of FOIA
requests, and processing of invoices.

Section IV. Procurement Management
4.1. Perform Contract Action
This activity involves performance by the vendor against stated requirements in the
contractual vehicle.
4.2. Send Completion Notice (if applicable)
This activity involves the acknowledgement on behalf of the vendor of completion of
services.
4.3. Record Contract Obligation
This activity interfaces construction obligations information from FABS to FAMIS.
4.3.a. Reconcile Foreign Currency and Exchange Rate (as necessary)
This activity converts invoices in foreign currency to US Dollars.
4.3.b. Exchange with Buyer (as necessary)
This activity involves resolving currency conversion concerns with the buyer.

4
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

4.4. Track Requirement Against Contract Ceiling (if applicable)
This activity involves the monitoring of contract expenditures against the contrac
ceiling.
4.5. Complete Order (if applicable)
This activity involves completing the order after it has been finished.
4.6. Monitor Delivery
This activity involves the monitoring of timely and complete delivery of
products and services per contractual obligations.
4.6.a. Monitor Vendor Compliance and Issues
This activity monitors contractor compliance with contract requirements for deliverable
items, utilizing vendor status reports, buyer acceptance reports, status reports, and
change requests. It involves setting up suspense system to alert of due dates, following
up on missed dates and applying the appropriate contractual remedy; pursuing nonconformance of contract item, and applying appropriate contractual remedy; meeting
with contractor and government to resolve non-conformance issues, providing approval
letters, Delegation of Procurement Authority (DPA) report, and revised milestones.
4.6.b. Process Changes (as necessary)
This activity processes changes, discontinues, or terminations of the order.
Is Change Within Scope?
This activity involves determining the steps necessary to make requested changes.
Under certain circumstances, a change request must return to the start of the process
and pass through all steps to completion. Under other circumstances, a change reques
may only be required to return to ‘Issue Contract Action’ (3.5) and proceed forward.
4.7. Receive Acceptance
This activity involves receiving buyer acceptance of goods and/or services when
necessary.
4.8. Perform Invoice Payment and Billing
This activity includes all sub-activities that comprise the invoicing, payment, and
collection process.

5
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

4.8.a. Send Invoice
This activity performs billing of buyers through posting sales transactions, preparing and
certifying buyer bills, and posting collections.
4.8.b. Receive Vendor Invoice(s)
This activity receives the vendor invoice submitted for services and/or products
delivered under a contract. It includes receiving and reviewing vendor inquiries,
invoices, checks, and credits.
4.8.c. Accept Goods and Services (as necessary)
This activity involves requesting and receiving buyer acceptance of goods and/or
services when necessary.
4.8.d. Perform Invoice Certification
This activity matches vendor invoice against accounts payable in COPS/FAMIS. For
FAMIS transactions, invoices are matched back to the contract.
4.8.e. Submit Payment Information
This activity involves submitting disbursement payments to vendors for services
rendered.
4.8.f. Update General Ledger
This activity involves updating the Financial Accounting Management Information
System (FAMIS) General Ledger subsystem.
4.8.g. Prepare Buyer Bill
This activity determines how the payment and buyer billing will be processed.
4.8.h. Reimburse Seller
This activity involves the receipt of funds from the buyer.
4.8.i. Update General Ledger
This activity involves updating the appropriate systems when submitting an invoice to
he buyer, as well as receiving payments from buyers.
4.9. Process Close-Outs
This activity performs contract/order close out.

6
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

Section V. Remote Ordering
5.1. Obtain Order Control Number
This activity involves the creation or receipt of an order control number from the buyer
for remote orders.
5.2. Perform Contract Action (for remote ordering)
This activity involves the establishment of a contract for services provided directly to a
buyer via a vendor, without the use of established contractual processes.
5.3. Remit Check and Required Ordering Information
This activity involves the submittal by the buyer of a check to the vendor for services
offered. The vendor then remits a check for 1% of the paid amount to PL/DITCO for use
of the established contract vehicle. The vendor is required to provide supporting check
documentation on an External Agency Ordering Spreadsheet report to PL/DITCO.
5.3. Record Accounts Receivable (Update General Ledger)
This activity involves updating the Financial Accounting Management Information
System (FAMIS) General Ledger subsystem.

7
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX F—OV-7 DATA CLASS MODEL
The data class diagram documents the data requirements grouped into classes of
information based on the operational context that supports the Enterprise Business
Modernization (EBM) business model. The EBM OV-7 will be a high-level
representation of the data classes and relationships needed to perform the information
echnology (IT) and telecommunications business processes. The EBM contractor will
need to further define the data elements and entities as part of overall solution
implementation.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX G—SV-1 TO-BE SYSTEM INTERFACE DESCRIPTION
The SV-1, System Interface Description, inventories systems and shows interfaces
between systems. As the system information matures, the system interfaces and
connectivity will be added to the SV-1. The Defense Information Technology
Contracting Organization (DITCO) Enterprise Business Management (EBM) solution’s
buyer, order, and financial management systems may have one or many external
interfaces with the Business Management Modernization Program (BMMP) corporate
applications and/or external applications. The data management component of the
system must establish many interfaces with external and BMMP corporate applications.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX H—TO-BE SV-4 SYSTEM FUNCTIONALITY DESCRIPTION
The To-Be SV-4, Systems Functionality Description, is a chart that describes the
relationships among the Ssystem Ffunctions and Ccapabilities. For purposes of the
PL/DITCO enterprise architecture,; a Ssystem fFunction as used in the SV-4 is defined
as a system component, e.g., a functional module of the system, which implements a
specific set of information technology (IT) functional requirements. System components
can be expressed logically in terms of the required functionality, e.g., Aaccounts
Rreceivable, or physically in terms of a specific technology, e.g., Ffinance and
Ccontrolling Mmodule. The SV-4 identifies the integration points between the Ssystem
rRequirements aligned by Ffunction and the Ccapabilities, which align to the function
sets. The SV-4 supports systems integration, particularly for development of application
systems.
This matrix is parsed by Ffunctional Aarea. The Y-axis contains the Ssystem
rRequirements rolled up into Ffunctional Aareas. These two columns are paired agains
he Tto-Bbe Ccapabilities on the X-axis. Each Rrequirement is evaluated against the
Ccapabilities and rated on how they correlate to one another. Correlations are
annotated within the matrix using “X.”.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX I—TO-BE TV-1 TECHNICAL ARCHITECTURE PROFILE
The following Technical Architecture Profile is a table extracting the technology
standards that apply to the Enterprise Business Modernization (EBM) architecture. The
echnical view (TV-1) is a minimal set of rules governing the arrangement, interaction,
and interdependence of system parts or elements. Its purpose is to ensure that a
system satisfies a specified set of operational requirements. The TV provides the
echnical systems implementation guidelines upon which engineering specifications are
based. Common building blocks are established, and product lines are developed. The
TV includes a collection of the technical standards, implementation conventions,
standard options, rules, and criteria organized into profiles that govern systems and
system elements for a given architecture.
To successfully implement the EBM requirements, specific technical requirements mus
be met. These technical requirements are shown on the Y-axis of the TV-1 matrix.
These requirements will allow the ability to evaluate the PL/DITCO capability
requirements with the technical standards provided by the Joint Technical Architecture
(JTA), which are shown on the X-axis. This evaluation will allow PL/DITCO to align its
echnical environment to the set of rules that governs the systems implementation and
operations. The EBM TV-1 is derived from the Acquisition Domain TV-1 and is in
compliance with Business Management Modernization Program (BMMP) requirements.
.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX J—FIT GAP ANALYSIS MATRIX
The Fit Gap Analysis Matrix is a chart that provides the alignment and relationships
between the system functional areas and the more detailed desired system capabilities.
The desired capabilities are grouped by system component, which provides a set of IT
functions. The right-most portion of the matrix enables prospective vendors to show
alignment between their proposed solution and the desired capabilities. If the capability
is satisfied by a commercial off the shelf product, it is important to annotate what the
ool and/or module of the tool is being used to meet the stated capability.
This matrix is parsed by Ffunctional Aarea. The Y-axis contains the SFfunctional
Aareas, and solution alignment. These columns are paired against the Tdesired
capabilities on the X-axis. Each Rrequirement is evaluated against the Ccapabilities
and rated on how they correlate to one another. Correlations are annotated within the
matrix using “X.”.

1
FINAL DRAFT v1.0

FINAL DRAFT
## CAPABILITIES REQUIREMENT DOCUMENT

APPENDIX K—SV-6 SYSTEMS DATA EXCHANGE MATRIX
The SV-6, System Data Exchange Matrix describes, in tabular format, data exchanges
among systems (or system components) within the project and between those systems
and systems that are external to the project. This matrix summarizes the interfaces and
describes their characteristics in system-specific terms, covering such characteristics as
specific protocols, and data formats. The characteristics contained in this matrix
supports capacity planning, and identifying interoperability and security mechanisms for
he exchanges.
**Note- The SV-6 is currently under development and will be included in the Capabilities
Requirements Document in the next release.

1
FINAL DRAFT v1.0

