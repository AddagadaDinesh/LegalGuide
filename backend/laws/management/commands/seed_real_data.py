from django.core.management.base import BaseCommand

from laws.models import Category, Law, LegalSection, LegalMatter

SOURCE_NOTE = (
    "Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023), Government of India. "
    "Official text is published at indiacode.nic.in; this entry was cross-verified "
    "against multiple independent legal-reference sources reproducing the bare act "
    "(apnilaw.com, lawrato.com, devgan.in, testbook.com) since the official site "
    "blocks automated fetches."
)

CONSTITUTION_SOURCE_NOTE = (
    "The Constitution of India, Part III (Fundamental Rights). Official text is "
    "published at indiacode.nic.in / legislative.gov.in; cross-verified against "
    "multiple independent legal-reference sources."
)

BNSS_SOURCE_NOTE = (
    "Bharatiya Nagarik Suraksha Sanhita, 2023 (Act No. 46 of 2023), Government of "
    "India — replaced the Code of Criminal Procedure, 1973 from 1 July 2024. "
    "Official text is published at indiacode.nic.in; this entry was cross-verified "
    "against multiple independent legal-reference sources (indiankanoon.org, "
    "apnilaw.com, drishtijudiciary.com, latestlaws.com) since the official site "
    "blocks automated fetches."
)

IT_ACT_SOURCE_NOTE = (
    "Information Technology Act, 2000, Government of India. Cross-verified against "
    "indiankanoon.org (bare-act reproduction), apnilaw.com, and sanhita.ai since "
    "indiacode.nic.in blocks automated fetches."
)

MV_ACT_SOURCE_NOTE = (
    "Motor Vehicles Act, 1988, as amended by the Motor Vehicles (Amendment) Act, "
    "2019 (in force from 1 September 2019). Cross-verified against indiankanoon.org "
    "and vakilsearch.com; one outdated secondary source with pre-2019 fine amounts "
    "was identified and excluded."
)

CPA_SOURCE_NOTE = (
    "Consumer Protection Act, 2019, Government of India (Chapter IV provisions in "
    "force from 20 July 2020). Cross-verified against indiankanoon.org, ibclaw.in, "
    "and consumerprotection.in."
)

HMA_SOURCE_NOTE = (
    "Hindu Marriage Act, 1955, Section 13 (as amended by the Marriage Laws "
    "(Amendment) Act, 1976). Cross-verified against indiankanoon.org and "
    "lawbhoomi.com."
)

DV_ACT_SOURCE_NOTE = (
    "Protection of Women from Domestic Violence Act, 2005, Section 12. "
    "Cross-verified against indiankanoon.org and advocategandhi.com."
)

TPA_SOURCE_NOTE = (
    "Transfer of Property Act, 1882, Section 54. Cross-verified against "
    "indiankanoon.org and the ipleaders.in explainer."
)

REGISTRATION_ACT_SOURCE_NOTE = (
    "Registration Act, 1908, Section 17 (including the sub-section (1A) "
    "added by the 2001 amendment). Cross-verified against indiankanoon.org "
    "and legalserviceindia.com."
)

POSH_SOURCE_NOTE = (
    "Sexual Harassment of Women at Workplace (Prevention, Prohibition and "
    "Redressal) Act, 2013, Section 9. Cross-verified against the bare act "
    "text (kanoongpt.in) and ssrana.in."
)

DOWRY_SOURCE_NOTE = (
    "Dowry Prohibition Act, 1961, Section 3 (as amended by the Dowry "
    "Prohibition (Amendment) Act, 1986). Cross-verified against "
    "indiankanoon.org, indiacode.nic.in, and casemine.com."
)

POCSO_SOURCE_NOTE = (
    "Protection of Children from Sexual Offences Act, 2012, as amended by "
    "the POCSO (Amendment) Act, 2019. Cross-verified against "
    "advocategandhi.com, prsindia.org, and apnilaw.com."
)

CSS_SOURCE_NOTE = (
    "Code on Social Security, 2020, Section 60 — in force nationwide from "
    "21 November 2025, replacing the Maternity Benefit Act, 1961. "
    "Cross-verified against the bare Code text (kanoongpt.in), with the "
    "specific 26/12-week durations corroborated by consistent independent "
    "secondary sources since the exact sub-clause was not directly fetchable."
)

IR_CODE_SOURCE_NOTE = (
    "Industrial Relations Code, 2020, Section 70 — in force nationwide "
    "from 21 November 2025, replacing Section 25F of the Industrial "
    "Disputes Act, 1947. Cross-verified directly against the bare Code "
    "text on indiankanoon.org."
)

LAST_VERIFIED = "2026-08-19"
RIGHTS_LAST_VERIFIED = "2026-08-20"
WEBSITE_PORT_VERIFIED = "2026-08-21"
NEW_CATEGORIES_VERIFIED = "2026-08-21"


class Command(BaseCommand):
    help = (
        "Removes the placeholder test law/section (TCL / TEST-001) and seeds the "
        "database with real, source-cited legal sections — including content "
        "ported from the existing LegalGuide website prototype after independent "
        "cross-verification against authoritative sources."
    )

    def handle(self, *args, **options):
        Law.objects.filter(short_name="TCL").delete()
        # Superseded by "Section 303" (renamed to match the verified bare-act title).
        LegalSection.objects.filter(section_number="Section 303(1)").delete()
        # Superseded by the "Theft & Snatching" / "Cheating & Fraud" matters below.
        LegalMatter.objects.filter(
            category__name="Criminal Law", name__in=["Theft", "Cheating"]
        ).delete()
        # Superseded by "Online financial fraud" (renamed, orphaned the old row).
        LegalMatter.objects.filter(
            category__name="Cyber Law", name="Online fraud"
        ).delete()

        # --- Categories ---------------------------------------------------
        criminal_law, _ = Category.objects.update_or_create(
            name="Criminal Law",
            defaults={
                "description": (
                    "Offences against the person, property, and public order, "
                    "and their prescribed punishments under Indian criminal law."
                )
            },
        )

        constitutional_law, _ = Category.objects.update_or_create(
            name="Constitutional Law",
            defaults={
                "description": (
                    "Fundamental rights, duties of citizens, and the governance "
                    "framework laid down by the Constitution of India."
                )
            },
        )

        Category.objects.filter(name="Know Your Rights").update(name="Arrest & Detention")
        rights_category, _ = Category.objects.update_or_create(
            name="Arrest & Detention",
            defaults={
                "description": (
                    "What to know if you or someone you know is stopped, "
                    "detained, or arrested — your rights during the process, "
                    "drawn from real statutory provisions."
                )
            },
        )

        empty_categories = {
            "Family Law": (
                "Marriage, divorce, maintenance, domestic relations, and "
                "child-related family matters under Indian law."
            ),
            "Property Law": (
                "Ownership, transfer, registration, and disputes relating to "
                "movable and immovable property."
            ),
            "Consumer Law": (
                "Rights of consumers against unfair trade practices, "
                "defective goods, and deficient services."
            ),
            "Motor Vehicle Law": (
                "Traffic regulation, licensing, registration, and accident "
                "claims under motor vehicle legislation."
            ),
            "Women's Rights": (
                "Legal protections and safeguards specific to women under "
                "Indian law."
            ),
            "Child Protection": (
                "Legal protections for children, including education, "
                "labour, and juvenile justice safeguards."
            ),
            "Labour & Employment": (
                "Rights and obligations relating to wages, workplace safety, "
                "and industrial disputes."
            ),
            "Cyber Law": (
                "Digital security, online fraud, data privacy, and "
                "cybercrime under Indian law."
            ),
        }
        categories_by_name = {
            criminal_law.name: criminal_law,
            constitutional_law.name: constitutional_law,
            rights_category.name: rights_category,
        }
        for name, description in empty_categories.items():
            cat, _ = Category.objects.update_or_create(
                name=name, defaults={"description": description}
            )
            categories_by_name[name] = cat

        cyber_law = categories_by_name["Cyber Law"]
        motor_vehicle_law = categories_by_name["Motor Vehicle Law"]
        consumer_law = categories_by_name["Consumer Law"]
        womens_rights = categories_by_name["Women's Rights"]
        family_law = categories_by_name["Family Law"]
        property_law = categories_by_name["Property Law"]
        child_protection = categories_by_name["Child Protection"]
        labour_law = categories_by_name["Labour & Employment"]

        # --- Laws -----------------------------------------------------------
        bns, _ = Law.objects.update_or_create(
            short_name="BNS 2023",
            defaults={
                "name": "Bharatiya Nyaya Sanhita, 2023",
                "category": criminal_law,
                "description": (
                    "India's principal criminal code, in force from 1 July 2024, "
                    "replacing the Indian Penal Code, 1860."
                ),
            },
        )

        constitution, _ = Law.objects.update_or_create(
            short_name="COI 1950",
            defaults={
                "name": "Constitution of India",
                "category": constitutional_law,
                "description": (
                    "The supreme law of India, laying down the fundamental rights "
                    "of citizens and the framework of government."
                ),
            },
        )

        rights_law, _ = Law.objects.update_or_create(
            short_name="Rights",
            defaults={
                "name": "Arrest & Detention Rights",
                "category": rights_category,
                "description": (
                    "An app-curated collection of real arrest/detention-rights "
                    "provisions drawn from the Bharatiya Nagarik Suraksha "
                    "Sanhita, 2023 and the Constitution of India — each section "
                    "below cites its true individual source, not this grouping."
                ),
            },
        )

        it_act, _ = Law.objects.update_or_create(
            short_name="IT Act",
            defaults={
                "name": "Information Technology Act, 2000",
                "category": cyber_law,
                "description": (
                    "India's principal law governing digital commerce, "
                    "cyber offences, and electronic signatures."
                ),
            },
        )

        mv_act, _ = Law.objects.update_or_create(
            short_name="MV Act",
            defaults={
                "name": "Motor Vehicles Act, 1988 (as amended 2019)",
                "category": motor_vehicle_law,
                "description": (
                    "Governs licensing, vehicle safety, traffic offences, and "
                    "penalties on Indian roads."
                ),
            },
        )

        cpa, _ = Law.objects.update_or_create(
            short_name="CPA",
            defaults={
                "name": "Consumer Protection Act, 2019",
                "category": consumer_law,
                "description": (
                    "Establishes consumer commissions and procedures for "
                    "redressal against defective goods and unfair trade practices."
                ),
            },
        )

        hma, _ = Law.objects.update_or_create(
            short_name="HMA 1955",
            defaults={
                "name": "Hindu Marriage Act, 1955",
                "category": family_law,
                "description": (
                    "Governs marriage, divorce, and related matters for "
                    "Hindus, Buddhists, Jains, and Sikhs in India."
                ),
            },
        )

        dv_act, _ = Law.objects.update_or_create(
            short_name="DV Act 2005",
            defaults={
                "name": "Protection of Women from Domestic Violence Act, 2005",
                "category": family_law,
                "description": (
                    "Provides a fast civil remedy — protection, "
                    "residence, custody, and monetary relief orders — "
                    "against domestic violence, independent of criminal "
                    "prosecution."
                ),
            },
        )

        bnss_maintenance, _ = Law.objects.update_or_create(
            short_name="BNSS-Maintenance",
            defaults={
                "name": "Bharatiya Nagarik Suraksha Sanhita, 2023",
                "category": family_law,
                "description": (
                    "The renumbered successor to the Code of Criminal "
                    "Procedure's maintenance provision (old Section 125), "
                    "in force from 1 July 2024."
                ),
            },
        )

        tpa, _ = Law.objects.update_or_create(
            short_name="TPA 1882",
            defaults={
                "name": "Transfer of Property Act, 1882",
                "category": property_law,
                "description": (
                    "Governs how ownership of property is transferred "
                    "between living persons, including sale, gift, and "
                    "lease."
                ),
            },
        )

        registration_act, _ = Law.objects.update_or_create(
            short_name="Registration Act 1908",
            defaults={
                "name": "Registration Act, 1908",
                "category": property_law,
                "description": (
                    "Specifies which property-related documents must be "
                    "registered with the Sub-Registrar to be legally "
                    "valid."
                ),
            },
        )

        posh_act, _ = Law.objects.update_or_create(
            short_name="POSH Act 2013",
            defaults={
                "name": (
                    "Sexual Harassment of Women at Workplace (Prevention, "
                    "Prohibition and Redressal) Act, 2013"
                ),
                "category": womens_rights,
                "description": (
                    "Requires workplaces to have a mechanism for women to "
                    "report and seek redress for sexual harassment."
                ),
            },
        )

        dowry_act, _ = Law.objects.update_or_create(
            short_name="Dowry Act 1961",
            defaults={
                "name": "Dowry Prohibition Act, 1961",
                "category": womens_rights,
                "description": "Criminalizes the giving, taking, or demanding of dowry.",
            },
        )

        pocso, _ = Law.objects.update_or_create(
            short_name="POCSO 2012",
            defaults={
                "name": "Protection of Children from Sexual Offences Act, 2012",
                "category": child_protection,
                "description": (
                    "India's special law addressing sexual abuse and "
                    "exploitation of children, with mandatory reporting "
                    "obligations."
                ),
            },
        )

        css, _ = Law.objects.update_or_create(
            short_name="CSS 2020",
            defaults={
                "name": "Code on Social Security, 2020",
                "category": labour_law,
                "description": (
                    "Consolidates social security laws including "
                    "maternity benefit, provident fund, and gratuity; in "
                    "force from 21 November 2025, replacing the "
                    "Maternity Benefit Act, 1961 among others."
                ),
            },
        )

        ir_code, _ = Law.objects.update_or_create(
            short_name="IR Code 2020",
            defaults={
                "name": "Industrial Relations Code, 2020",
                "category": labour_law,
                "description": (
                    "Consolidates laws on trade unions, industrial "
                    "disputes, and conditions of employment; in force "
                    "from 21 November 2025, replacing the Industrial "
                    "Disputes Act, 1947 among others."
                ),
            },
        )

        # --- Legal sections ---------------------------------------------
        sections = [
            dict(
                law=bns,
                section_number="Section 103(1)",
                title="Punishment for Murder",
                legal_text=(
                    "Whoever commits murder shall be punished with death or "
                    "imprisonment for life, and shall also be liable to fine."
                ),
                simple_explanation=(
                    "If someone unlawfully kills another person with the intent "
                    "to kill (or knowledge that their act is likely to cause "
                    "death), it is murder, and it carries the harshest penalties "
                    "in Indian criminal law."
                ),
                purpose="Protects the right to life by deterring and punishing unlawful killing.",
                punishment="Death or imprisonment for life, and fine.",
                relevant_documents="FIR, post-mortem/medical report, forensic evidence, witness statements.",
                source=SOURCE_NOTE,
            ),
            dict(
                law=bns,
                section_number="Section 303",
                title="Theft",
                legal_text=(
                    "Whoever, intending to take dishonestly any movable property "
                    "out of the possession of any person without that person's "
                    "consent, moves that property in order to such taking, is "
                    "said to commit theft."
                ),
                simple_explanation=(
                    "Taking someone else's movable property without their "
                    "permission, intending to keep it dishonestly, is theft — "
                    "for example, a phone, vehicle, or cash taken without consent."
                ),
                purpose="Protects personal property from being dishonestly taken by others.",
                punishment=(
                    "First conviction: imprisonment up to 3 years, or fine, or "
                    "both. Second or subsequent conviction: rigorous imprisonment "
                    "of 1 to 5 years, with fine. For first-time theft of property "
                    "under Rs. 5,000, with the property returned/restored, "
                    "community service may apply instead."
                ),
                key_elements=(
                    "The property must be movable (phone, vehicle, jewellery, cash).\n"
                    "The property was in the possession of another person.\n"
                    "The taking was done dishonestly, without the owner's consent.\n"
                    "The property was moved in order to take it."
                ),
                relevant_information=(
                    "Exact date, time, and location where the property was last seen.\n"
                    "Proof of ownership (invoice, IMEI number, registration certificate).\n"
                    "Whether the item was locked, in a vehicle, or in a public space."
                ),
                relevant_documents="FIR / police complaint, proof of ownership/possession, police seizure memo, IMEI/serial number documentation.",
                keywords="theft, stole, phone, stealing, laptop, wallet, property, dishonest, bns 303",
                badge="Most Searched",
                source="Bharatiya Nyaya Sanhita, 2023, Section 303. Cross-verified against ipleaders.in, apnilaw.com, testbook.com, and lawrato.com (official indiacode.nic.in blocks automated fetches).",
            ),
            dict(
                law=bns,
                section_number="Section 304",
                title="Snatching",
                legal_text=(
                    "Theft is 'snatching' if, in order to commit theft, the "
                    "offender suddenly or quickly or forcibly seizes or secures "
                    "or grabs or takes away from any person or from his "
                    "possession any movable property."
                ),
                simple_explanation=(
                    "When someone suddenly grabs your phone or chain from your "
                    "hand or neck and runs away, it is classified as snatching — "
                    "a distinct, standalone offence with no direct IPC equivalent."
                ),
                purpose="Provides a distinct legal provision addressing street crimes involving sudden, forcible grabbing of valuables.",
                punishment="Imprisonment of either description for a term which may extend to three years, and the offender shall also be liable to fine.",
                key_elements=(
                    "Commission of theft by sudden seizure or grabbing.\n"
                    "Property was held or worn by the person.\n"
                    "Sudden force or speed used to dispossess the owner."
                ),
                relevant_information=(
                    "Exact spot of occurrence and route taken by the accused.\n"
                    "Vehicle description if a bike/scooter was used.\n"
                    "Any physical injury sustained during the snatching."
                ),
                relevant_documents="FIR copy, medical examination report if injury occurred, invoice showing ownership of the snatched item.",
                keywords="snatching, chain snatching, phone snatching, grabbed, street crime, bns 304",
                source="Bharatiya Nyaya Sanhita, 2023, Section 304. Cross-verified against devgan.in, lawrato.com, vakilsearch.com, and apnilaw.com.",
            ),
            dict(
                law=bns,
                section_number="Section 309",
                title="Robbery",
                legal_text=(
                    "In all robbery there is either theft or extortion. Theft is "
                    "robbery if, in order to the committing of the theft, or in "
                    "committing the theft, or in carrying away property obtained "
                    "by the theft, the offender voluntarily causes or attempts to "
                    "cause death, hurt, or wrongful restraint, or fear of instant "
                    "death, instant hurt, or instant wrongful restraint."
                ),
                simple_explanation=(
                    "If someone steals from you by threatening you, hurting you, "
                    "or putting you in fear of physical harm, the offence "
                    "escalates from simple theft to robbery."
                ),
                purpose="Penalizes the violent element introduced during an unauthorized taking of property.",
                punishment=(
                    "Rigorous imprisonment for a term up to 10 years, and fine; if "
                    "committed on the highway between sunset and sunrise, up to 14 "
                    "years. Attempted robbery: up to 7 years rigorous imprisonment "
                    "and fine. Robbery causing hurt: imprisonment for life or "
                    "rigorous imprisonment up to 10 years, and fine."
                ),
                key_elements=(
                    "Theft or extortion was being committed.\n"
                    "Offender caused, or attempted to cause, hurt, death, or wrongful restraint.\n"
                    "Action created immediate fear of physical harm."
                ),
                relevant_information=(
                    "Nature of any weapon or threat used.\n"
                    "Number of persons involved.\n"
                    "Physical injuries caused to victim or bystanders."
                ),
                relevant_documents="FIR mentioning weapons/threats used, medico-legal case (MLC) report, witness statements.",
                keywords="robbery, threat, weapon, force, extortion, dacoity, bns 309",
                source="Bharatiya Nyaya Sanhita, 2023, Section 309. Cross-verified against lawrato.com, testbook.com, and vakilsearch.com.",
            ),
            dict(
                law=bns,
                section_number="Section 318",
                title="Cheating",
                legal_text=(
                    "Whoever, by deceiving any person, fraudulently or "
                    "dishonestly induces the person so deceived to deliver any "
                    "property to any person, or to consent that any person shall "
                    "retain any property, or intentionally induces the person so "
                    "deceived to do or omit to do anything which he would not do "
                    "or omit if he were not so deceived, and which act or "
                    "omission causes or is likely to cause damage or harm to "
                    "that person in body, mind, reputation or property, is said "
                    "to cheat. A dishonest concealment of facts is a deception "
                    "within the meaning of this section."
                ),
                simple_explanation=(
                    "Tricking or deceiving someone into handing over property, "
                    "money, or a document, or into doing/not doing something "
                    "that harms them, counts as cheating. Sub-section 318(4) — "
                    "dishonestly inducing delivery of property — is the direct "
                    "successor to the old 'Section 420' cheating offence."
                ),
                purpose="Protects individuals and businesses from fraud and deception.",
                punishment=(
                    "Graded by sub-section: general cheating (318(2)) — up to 3 "
                    "years, or fine, or both. Cheating breaching a duty to "
                    "protect the victim's interests (318(3)) — up to 5 years, or "
                    "fine, or both. Cheating that induces delivery of property or "
                    "alters a valuable security (318(4), the old 'Section 420' "
                    "offence) — up to 7 years AND fine (mandatory at this tier)."
                ),
                key_elements=(
                    "Deception of any person.\n"
                    "Fraudulent or dishonest inducement to deliver property or make payments.\n"
                    "Intentional inducement causing damage or harm to the person deceived."
                ),
                relevant_information=(
                    "Communication records (messages, emails, call logs).\n"
                    "Bank transfer receipts, UPI transaction IDs, cheque copies.\n"
                    "Promises made in writing or verbally."
                ),
                relevant_documents="Bank statement highlighting fraudulent transactions, agreements/receipts/invoices, screenshots of chats, police complaint copy.",
                keywords="cheating, fraud, scam, deception, fake, duped, 420, money fraud, bns 318",
                badge="Popular",
                source="Bharatiya Nyaya Sanhita, 2023, Section 318. Cross-verified against lawrato.com, apnilaw.com, drishtijudiciary.com, and ezylegal.in. Note: the section's heading is 'Cheating' generally; 'inducing delivery of property' specifically describes sub-section (4).",
            ),
            dict(
                law=bns,
                section_number="Section 316",
                title="Criminal Breach of Trust",
                legal_text=(
                    "Whoever, being in any manner entrusted with property, or "
                    "with any dominion over property, dishonestly misappropriates "
                    "or converts to his own use that property, or dishonestly "
                    "uses or disposes of that property in violation of any "
                    "direction of law or of any legal contract which he has made "
                    "touching the discharge of such trust, commits criminal "
                    "breach of trust."
                ),
                simple_explanation=(
                    "If you give your car, money, or goods to someone you "
                    "trusted (an employee, partner, or custodian) for safekeeping, "
                    "and they use it for their own gain without your permission, "
                    "that is a criminal breach of trust."
                ),
                purpose="Holds custodians, fiduciaries, and trustees accountable for entrusted property.",
                punishment=(
                    "General offence: imprisonment up to 5 years, or fine, or "
                    "both. Aggravated categories (carriers, warehouse-keepers, "
                    "clerks/servants): up to 7 years and fine. By a public "
                    "servant, banker, merchant, or agent: imprisonment for life "
                    "or up to 10 years, and fine."
                ),
                key_elements=(
                    "Entrustment of property to the accused.\n"
                    "Dishonest misappropriation or conversion to their own use.\n"
                    "Violation of a legal direction or agreement governing the trust."
                ),
                relevant_information=(
                    "Proof of entrustment (handover receipt, contract, partnership deed).\n"
                    "Demand notice requesting return of the property.\n"
                    "Refusal or evasive response from the accused."
                ),
                relevant_documents="Agreement/contract, receipts showing transfer of custody, legal notice demanding restitution, bank records.",
                keywords="breach of trust, entrusted, misappropriation, partner, agent, deposit, bns 316",
                source="Bharatiya Nyaya Sanhita, 2023, Section 316. Cross-verified against devgan.in and lawrato.com.",
            ),
            dict(
                law=bns,
                section_number="Section 351",
                title="Criminal Intimidation",
                legal_text=(
                    "Whoever threatens another with any injury to his person, "
                    "reputation or property, or to the person or reputation of "
                    "any one in whom that person is interested, with intent to "
                    "cause alarm to that person, or to cause that person to do "
                    "any act which he is not legally bound to do, or to omit to "
                    "do any act which that person is legally entitled to do, as "
                    "the means of avoiding the execution of such threat, commits "
                    "criminal intimidation."
                ),
                simple_explanation=(
                    "When someone threatens to beat you up, ruin your "
                    "reputation, damage your property, or harm your family to "
                    "scare you or force you to act against your will."
                ),
                purpose="Protects individual mental peace, liberty, and physical safety against threats.",
                punishment=(
                    "Basic threats: imprisonment up to 2 years, or fine, or "
                    "both. Threats of death, grievous hurt, destruction of "
                    "property by fire, or imputing unchastity to a woman "
                    "(aggravated): up to 7 years, or fine, or both. A further 2 "
                    "years may be added if the threat was made anonymously."
                ),
                key_elements=(
                    "Threat of injury to person, reputation, or property.\n"
                    "Intent to cause alarm or force the person to act against their will."
                ),
                relevant_information=(
                    "Audio recordings, text messages, or letters containing threats.\n"
                    "Details of any prior dispute or context.\n"
                    "Eyewitnesses present during the incident."
                ),
                relevant_documents="Audio/video evidence of the threats, exported chat logs with metadata, FIR copy.",
                keywords="threat, intimidation, blackmail, danger, harm, warning, bns 351",
                badge="Frequent",
                source="Bharatiya Nyaya Sanhita, 2023, Section 351. Cross-verified against testbook.com, lawrato.com, vakilsearch.com, and righttolaw.com.",
            ),
            dict(
                law=bns,
                section_number="Section 115",
                title="Voluntarily Causing Hurt",
                legal_text=(
                    "Whoever does any act with the intention of thereby causing "
                    "hurt to any person, or with the knowledge that he is likely "
                    "thereby to cause hurt to any person, and does thereby cause "
                    "hurt to any person, is said to 'voluntarily cause hurt'."
                ),
                simple_explanation=(
                    "When someone intentionally punches, slaps, kicks, or "
                    "physically hits you and causes bodily pain or injury, it is "
                    "treated as voluntarily causing hurt."
                ),
                purpose="Protects bodily integrity and penalizes physical violence.",
                punishment="Imprisonment of either description for a term up to 1 year, or fine up to Rs. 10,000, or both.",
                key_elements=(
                    "Bodily pain, disease, or infirmity caused.\n"
                    "Intention to cause hurt, or knowledge that the act is likely to cause hurt."
                ),
                relevant_information=(
                    "Time and place of the assault.\n"
                    "Names of witnesses present.\n"
                    "Whether weapons or objects were used (which may elevate the offence)."
                ),
                relevant_documents="Medico-legal case (MLC) report, doctor's prescription/treatment bill, photographs of injuries, FIR.",
                keywords="assault, hurt, beaten, injury, fight, physical violence, bns 115",
                source="Bharatiya Nyaya Sanhita, 2023, Section 115. Cross-verified against lawrato.com, vidhijudicial.com, testbook.com, and apnilaw.com.",
            ),
            dict(
                law=bns,
                section_number="Section 356",
                title="Defamation",
                legal_text=(
                    "Whoever, by words either spoken or intended to be read, or "
                    "by signs or by visible representations, makes or publishes "
                    "any imputation concerning any person intending to harm, or "
                    "knowing or having reason to believe that such imputation "
                    "will harm, the reputation of such person, is said to "
                    "defame that person."
                ),
                simple_explanation=(
                    "When someone publicly spreads false, harmful statements or "
                    "posts about you, knowing it will damage your reputation."
                ),
                purpose="Safeguards an individual's dignity, social standing, and reputation.",
                punishment=(
                    "Simple imprisonment up to 2 years, or fine, or both, or "
                    "community service. The offence is non-cognizable and "
                    "bailable, generally triable by a Magistrate of the first class."
                ),
                key_elements=(
                    "Making or publishing an imputation.\n"
                    "The imputation concerns the aggrieved person.\n"
                    "Intention or knowledge that it will harm reputation.\n"
                    "Does not fall under a recognized legal exception (e.g. truth for public good)."
                ),
                relevant_information=(
                    "Exact words, audio, video, or publication used.\n"
                    "Proof that the publication reached third parties.\n"
                    "Evidence disproving the false claims."
                ),
                relevant_documents="Screenshots of posts with URLs/timestamps, legal notice demanding retraction, witness affidavits.",
                keywords="defamation, reputation, slander, libel, false claim, social media post, bns 356",
                source="Bharatiya Nyaya Sanhita, 2023, Section 356. Cross-verified against devgan.in, lawrato.com, testbook.com, and vakilsearch.com.",
            ),
            dict(
                law=bns,
                section_number="Section 74",
                title="Assault or Criminal Force to Woman with Intent to Outrage her Modesty",
                legal_text=(
                    "Whoever assaults or uses criminal force to any woman, "
                    "intending to outrage or knowing it to be likely that he "
                    "will thereby outrage her modesty, shall be punished with "
                    "imprisonment of either description for a term which shall "
                    "not be less than one year but which may extend to five "
                    "years, and shall also be liable to fine."
                ),
                simple_explanation=(
                    "Protects women from unwanted physical touch, aggressive "
                    "advances, or physical assault aimed at violating personal "
                    "dignity — the direct successor to old IPC Section 354."
                ),
                purpose="Enforces zero tolerance for gender-based violence and protects women's dignity and safety.",
                punishment="Imprisonment of either description, not less than 1 year and up to 5 years, and fine. Cognizable and non-bailable.",
                key_elements=(
                    "Assault or use of criminal force against a woman.\n"
                    "Intention to outrage her modesty, or knowledge that it is likely to do so."
                ),
                relevant_information=(
                    "Precise location, time, and sequence of events.\n"
                    "Eyewitnesses or CCTV coverage.\n"
                    "Identity of the perpetrator (known person, colleague, stranger)."
                ),
                relevant_documents="FIR / Zero FIR, statement before a Magistrate, medical examination report if force was used, digital evidence.",
                keywords="women safety, molestation, outrage modesty, harassment, stalking, bns 74",
                badge="Protection Law",
                source="Bharatiya Nyaya Sanhita, 2023, Section 74. Cross-verified against devgan.in, writinglaw.com, vakilsearch.com, testbook.com, and lawrato.com.",
            ),
            dict(
                law=it_act,
                section_number="Section 66D",
                title="Cheating by Personation by Using Computer Resource",
                legal_text=(
                    "Whoever, by means of any communication device or computer "
                    "resource cheats by personation, shall be punished with "
                    "imprisonment of either description for a term which may "
                    "extend to three years and shall also be liable to fine "
                    "which may extend to one lakh rupees."
                ),
                simple_explanation=(
                    "If someone creates a fake identity online (pretending to be "
                    "a bank official, army officer, or friend) over a call, "
                    "message, or website to trick you into transferring money or "
                    "sharing your OTP/credentials, this is the applicable offence."
                ),
                purpose="Combats digital impersonation, phishing attacks, and online financial fraud.",
                punishment="Imprisonment of either description up to 3 years, and fine up to Rs. 1,00,000.",
                key_elements=(
                    "Use of a computer resource or communication device.\n"
                    "Deception by pretending to be someone else.\n"
                    "Cheating and dishonest inducement."
                ),
                relevant_information=(
                    "Transaction ID, UTR number, beneficiary account details.\n"
                    "Phone numbers, emails, or website links used by the fraudster.\n"
                    "Acknowledgement number from cybercrime.gov.in (Helpline 1930)."
                ),
                relevant_documents="National Cyber Crime Reporting Portal complaint receipt, bank statement, screenshots of SMS/OTP requests and chats.",
                keywords="cyber fraud, online scam, phishing, fake profile, otp fraud, impersonation, it act 66d",
                badge="Trending",
                source="Information Technology Act, 2000, Section 66D. Cross-verified against apnilaw.com, sanhita.ai, kanoongpt.in, and worldlawdigest.com.",
            ),
            dict(
                law=it_act,
                section_number="Section 66C",
                title="Punishment for Identity Theft",
                legal_text=(
                    "Whoever, fraudulently or dishonestly make use of the "
                    "electronic signature, password or any other unique "
                    "identification feature of any other person, shall be "
                    "punished with imprisonment of either description for a "
                    "term which may extend to three years and shall also be "
                    "liable to fine which may extend to rupees one lakh."
                ),
                simple_explanation=(
                    "If someone steals your email password, social media login, "
                    "UPI PIN, or digital signature and uses it without your "
                    "permission, they can be prosecuted under this section."
                ),
                purpose="Safeguards digital identities, passwords, and electronic credentials.",
                punishment="Imprisonment of either description up to 3 years, and fine up to Rs. 1,00,000.",
                key_elements=(
                    "Unauthorized use of electronic signature, password, or biometric data.\n"
                    "Done dishonestly or fraudulently."
                ),
                relevant_information=(
                    "Access logs and login-alert emails from service providers.\n"
                    "IP address / device information in security logs, if available.\n"
                    "Services accessed without authorization."
                ),
                relevant_documents="Security alert emails, screenshots of unauthorized account changes, cyber police complaint copy.",
                keywords="identity theft, password, digital signature, biometric, hacked, stolen credentials, it act 66c",
                source="Information Technology Act, 2000, Section 66C. Cross-verified against indiankanoon.org, apnilaw.com, and worldlawdigest.com.",
            ),
        ]

        rights_sections = [
            dict(
                law=rights_law,
                section_number="BNSS Section 35",
                title="When Police May Arrest Without Warrant",
                legal_text=(
                    "A police officer may arrest a person without an order from "
                    "a Magistrate and without a warrant where a cognizable "
                    "offence is committed in their presence, or on credible "
                    "information/reasonable suspicion. For offences punishable "
                    "with less than seven years' imprisonment, the officer must "
                    "additionally believe arrest is necessary for a specified "
                    "purpose (preventing further offence, ensuring proper "
                    "investigation, preventing evidence tampering, etc.) and "
                    "must record reasons in writing — both when making, and when "
                    "choosing not to make, the arrest."
                ),
                simple_explanation=(
                    "Explains when police can arrest someone without a "
                    "magistrate's warrant. For offences carrying under 7 years, "
                    "arrest is meant to be the exception: the officer must "
                    "normally issue a notice to appear instead, unless there's a "
                    "specific, recorded reason arrest is necessary."
                ),
                purpose="Balances law-enforcement power with constitutional rights against arbitrary detention.",
                punishment="Not a penal provision — a procedural safeguard governing when and how police may arrest.",
                key_elements=(
                    "Cognizable offence committed in the presence of the police officer.\n"
                    "Reasonable complaint or credible information for offences with prescribed punishments.\n"
                    "For offences under 7 years: a notice of appearance is ordinarily issued instead of arrest.\n"
                    "Mandatory recording of reasons in writing, whether or not an arrest is made."
                ),
                relevant_information=(
                    "Did the officer inform the arrested person of the exact grounds of arrest?\n"
                    "Was an arrest memo prepared with date, time, and witness signature?\n"
                    "Was a family member or friend informed immediately?"
                ),
                relevant_documents="Copy of arrest memo, copy of FIR/complaint, intimation memo sent to family/nominated person.",
                keywords="arrest, police, custody, warrant, grounds of arrest, rights, bnss 35",
                badge="Arrest Rights",
                source="Bharatiya Nagarik Suraksha Sanhita, 2023, Section 35. Cross-verified against indiankanoon.org, drishtijudiciary.com, leadindia.law, and vaishlaw.com.",
            ),
            dict(
                law=rights_law,
                section_number="BNSS Section 47",
                title="Person Arrested to be Informed of Grounds of Arrest and of Right to Bail",
                legal_text=(
                    "Every police officer or other person arresting any person "
                    "without warrant shall forthwith communicate to him full "
                    "particulars of the offence for which he is arrested or "
                    "other grounds for such arrest. Where a police officer "
                    "arrests without warrant any person other than a person "
                    "accused of a non-bailable offence, he shall inform the "
                    "person arrested that he is entitled to be released on bail "
                    "and that he may arrange for sureties."
                ),
                simple_explanation=(
                    "If you're arrested, the police must immediately tell you "
                    "why you're being arrested — and if it's for a bailable "
                    "offence, they must tell you you're entitled to bail."
                ),
                purpose="Prevents arbitrary arrest by requiring the reason to be stated immediately, upholding Article 22.",
                punishment="Not a penal provision — a procedural safeguard; non-compliance can render an arrest illegal and support release via habeas corpus.",
                key_elements=(
                    "Immediate communication of specific allegations and section numbers.\n"
                    "Information regarding the bailable nature of the alleged offence (for bailable offences only).\n"
                    "Right to arrange sureties if the offence is bailable."
                ),
                relevant_information=(
                    "Whether the offence is classified as bailable or non-bailable.\n"
                    "Name and badge number of the arresting officer."
                ),
                relevant_documents="Arrest memo stating the grounds, bail application, surety identification documents.",
                keywords="arrested, bail, rights, grounds, police custody, lawyer, bnss 47",
                badge="Essential",
                source="Bharatiya Nagarik Suraksha Sanhita, 2023, Section 47. Cross-verified against indiankanoon.org, apnilaw.com, latestlaws.com, sanhita.ai, and truelawyer.in.",
            ),
            dict(
                law=rights_law,
                section_number="BNSS Section 48",
                title="Right to Inform a Relative or Friend of the Arrest",
                legal_text=(
                    "The police officer or person making the arrest shall "
                    "forthwith give information regarding the arrest and the "
                    "place where the arrested person is being held, to a "
                    "relative, friend, or other person nominated by the "
                    "arrested person for that purpose."
                ),
                simple_explanation=(
                    "You have the right to have the police tell someone you "
                    "choose — a relative or friend — that you've been arrested "
                    "and where you're being held."
                ),
                purpose="Ensures the arrested person is not held incommunicado.",
                punishment="Not a penal provision — a procedural safeguard for the arrested person.",
                relevant_documents="Arrest memo naming the informed person.",
                source=BNSS_SOURCE_NOTE,
            ),
            dict(
                law=rights_law,
                section_number="BNSS Section 43(5)",
                title="Restriction on Arrest of Women After Sunset",
                legal_text=(
                    "As a general rule, no woman shall be arrested after "
                    "sunset and before sunrise. Where exceptional circumstances "
                    "exist, a woman police officer must obtain prior written "
                    "permission of a Magistrate of the First Class within whose "
                    "local jurisdiction the offence is committed or the arrest "
                    "is to be made."
                ),
                simple_explanation=(
                    "Ordinarily, a woman cannot be arrested at night. If there's "
                    "an exceptional reason to do so, it must be a woman police "
                    "officer making the arrest, with a magistrate's prior "
                    "written permission."
                ),
                purpose="Protects women from arrest procedures at night absent exceptional justification.",
                punishment="Not a penal provision — a procedural safeguard for women being arrested.",
                relevant_documents="Magistrate's written permission (in exceptional cases).",
                source=BNSS_SOURCE_NOTE,
            ),
            dict(
                law=rights_law,
                section_number="BNSS Section 58",
                title="Production Before a Magistrate Within 24 Hours",
                legal_text=(
                    "No police officer shall detain a person arrested without "
                    "a warrant in custody for a period longer than is "
                    "reasonable, and such period shall not exceed twenty-four "
                    "hours, excluding the time necessary for travel from the "
                    "place of arrest to the Magistrate's court, without a "
                    "special order of a Magistrate. Every arrested person shall "
                    "be produced before the nearest Magistrate within that "
                    "24-hour period."
                ),
                simple_explanation=(
                    "The police can't hold you for more than 24 hours (not "
                    "counting travel time to court) without a magistrate's "
                    "order — you must be produced before a magistrate within "
                    "that time."
                ),
                purpose="Prevents indefinite detention without judicial oversight.",
                punishment="Not a penal provision — a procedural safeguard for the arrested person.",
                relevant_documents="Remand order, production record.",
                source=BNSS_SOURCE_NOTE,
            ),
            dict(
                law=rights_law,
                section_number="Article 22(1)",
                title="Right to Consult and Be Defended by a Legal Practitioner",
                legal_text=(
                    "No person who is arrested shall be detained in custody "
                    "without being informed, as soon as may be, of the grounds "
                    "for such arrest nor shall he be denied the right to "
                    "consult, and to be defended by, a legal practitioner of "
                    "his choice."
                ),
                simple_explanation=(
                    "You have the constitutional right to consult a lawyer of "
                    "your choice and be defended by them. If you can't afford "
                    "one, the Supreme Court (Hussainara Khatoon v. State of "
                    "Bihar, 1980) held the state must provide free legal aid — "
                    "see the Legal Help section of this app for the NALSA "
                    "helpline."
                ),
                purpose="Guarantees access to legal representation as a fundamental right.",
                punishment="Not a penal provision — a fundamental constitutional right.",
                relevant_documents="None required to exercise this right.",
                source=CONSTITUTION_SOURCE_NOTE,
            ),
        ]

        website_port_sections = [
            dict(
                law=constitution,
                section_number="Article 21",
                title="Protection of Life and Personal Liberty",
                legal_text=(
                    "No person shall be deprived of his life or personal liberty "
                    "except according to procedure established by law."
                ),
                simple_explanation=(
                    "Every person — citizen or not — has the fundamental right "
                    "not to be deprived of life or personal liberty, except "
                    "through a fair legal process. Courts have interpreted this "
                    "broadly to include rights to dignity, privacy, livelihood, "
                    "a clean environment, and health."
                ),
                purpose="Guarantees the fundamental right to life and personal liberty against arbitrary state action.",
                punishment=(
                    "Not a penal provision — remedies are constitutional, via a "
                    "writ petition under Article 32 (Supreme Court) or Article "
                    "226 (High Court)."
                ),
                relevant_documents="Writ petition, evidence of the rights violation.",
                source=CONSTITUTION_SOURCE_NOTE,
            ),
            dict(
                law=mv_act,
                section_number="Section 185",
                title="Driving by a Drunken Person or by a Person Under the Influence of Drugs",
                legal_text=(
                    "Whoever, while driving, or attempting to drive, a motor "
                    "vehicle has, in his blood, alcohol exceeding 30 mg per 100 "
                    "ml of blood detected in a test by a breath analyser, or is "
                    "under the influence of a drug to such an extent as to be "
                    "incapable of exercising proper control over the vehicle, "
                    "shall be punishable."
                ),
                simple_explanation=(
                    "Driving any vehicle after drinking alcohol, if a "
                    "breathalyzer shows alcohol above the legal limit (30mg per "
                    "100ml), is an offence punishable with fines and possible jail."
                ),
                purpose="Prevents road fatalities and discourages driving under substance influence.",
                punishment=(
                    "First offence: imprisonment up to 6 months, or fine up to "
                    "Rs. 10,000, or both. Second or subsequent offence within 3 "
                    "years: imprisonment up to 2 years, or fine up to Rs. "
                    "15,000, or both (figures as increased by the Motor "
                    "Vehicles (Amendment) Act, 2019, effective 1 September 2019)."
                ),
                key_elements=(
                    "Driving or attempting to drive a motor vehicle in a public place.\n"
                    "Blood alcohol content exceeding 30 mg/100 ml, or incapable of proper control due to drugs."
                ),
                relevant_information=(
                    "Breath analyser test slip / reading.\n"
                    "Blood sample testing report, if taken.\n"
                    "Challan / impound memo issued by traffic police."
                ),
                relevant_documents="E-challan copy, driving license and RC, breathalyzer test reading, vehicle insurance policy.",
                keywords="drunk driving, alcohol, traffic, breathalyzer, fine, driving license, accident, mv act 185",
                source=MV_ACT_SOURCE_NOTE,
            ),
            dict(
                law=cpa,
                section_number="Section 35",
                title="Manner in Which Complaint Shall Be Made",
                legal_text=(
                    "A complaint may be filed before the District Commission by "
                    "the consumer to whom the goods/services were sold or "
                    "provided, or who alleges an unfair trade practice; by a "
                    "recognized consumer association; by one or more consumers, "
                    "with the Commission's permission, where numerous consumers "
                    "have the same interest; or by the Central Government, "
                    "Central Authority, or a State Government."
                ),
                simple_explanation=(
                    "If a company sold you a defective product, refused a "
                    "rightful refund, or gave poor service, this section "
                    "explains who can file a case in the District Consumer "
                    "Commission and how — including electronic filing."
                ),
                purpose="Provides an accessible mechanism for consumers to seek redress against sellers and service providers.",
                punishment="Not a penal provision — a procedural provision governing who may file a complaint and how.",
                key_elements=(
                    "Complainant must be a 'consumer' (bought for consideration, not commercial resale).\n"
                    "Defect in goods, deficiency in service, or unfair trade practice.\n"
                    "Complaint (and fee payment) may be filed electronically, per prescribed rules."
                ),
                relevant_information=(
                    "Invoice number, purchase date, and payment proof.\n"
                    "Warranty/guarantee card details.\n"
                    "Customer care complaints, email exchanges, and ticket numbers."
                ),
                relevant_documents="Tax invoice, warranty card copy, written communication with seller, legal notice sent (if any).",
                keywords="consumer, defective product, refund, warranty, consumer court, e-commerce fraud, cpa 35",
                source=CPA_SOURCE_NOTE,
            ),
        ]

        new_categories_sections = [
            dict(
                law=hma,
                section_number="Section 13",
                title="Grounds for Divorce",
                legal_text=(
                    "Either spouse may petition for divorce on grounds "
                    "including adultery, cruelty, desertion for two or "
                    "more continuous years, conversion to another "
                    "religion, unsoundness of mind, communicable "
                    "venereal disease, renunciation of the world, or not "
                    "being heard of as alive for seven years. A wife has "
                    "additional exclusive grounds, including the "
                    "husband's bigamy, rape, sodomy, or bestiality."
                ),
                simple_explanation=(
                    "Lets a husband or wife apply to court for divorce "
                    "on specific grounds like cruelty, desertion, or "
                    "adultery. Divorce can also be obtained by mutual "
                    "consent under a separate provision (Section 13B) "
                    "without needing to prove fault."
                ),
                purpose="Provides a legal way to end a broken marriage, balancing marital stability with protection from abuse or injustice.",
                punishment="Not a penal provision — the remedy is a court decree dissolving the marriage.",
                key_elements=(
                    "Petitioner must be the aggrieved husband or wife.\n"
                    "A specific statutory ground must be proved with evidence.\n"
                    "Desertion must be for a continuous period of two years or more.\n"
                    "A wife has additional exclusive grounds beyond those available to a husband."
                ),
                relevant_information=(
                    "Marriage certificate or proof of a valid Hindu marriage.\n"
                    "Dates and evidence supporting the specific ground claimed.\n"
                    "Whether mutual consent divorce (faster, no-fault) is a realistic option instead."
                ),
                relevant_documents="Marriage certificate, divorce petition, evidence supporting the ground claimed (medical records, communication records, witness statements).",
                keywords="divorce, separation, marriage breakdown, cruelty, desertion, adultery, hindu marriage act, section 13",
                source=HMA_SOURCE_NOTE,
            ),
            dict(
                law=dv_act,
                section_number="Section 12",
                title="Application to Magistrate for Protection and Other Orders",
                legal_text=(
                    "An aggrieved person, a Protection Officer, or "
                    "another person on her behalf may apply to the "
                    "Magistrate for one or more reliefs under the Act. "
                    "The Magistrate must consider any Domestic Incident "
                    "Report before deciding, must ordinarily hold the "
                    "first hearing within three days of the application "
                    "being filed, and should endeavour to dispose of the "
                    "application within sixty days of the first hearing."
                ),
                simple_explanation=(
                    "Lets a woman facing domestic violence go directly "
                    "to a Magistrate for protection, residence, monetary "
                    "relief, custody, or compensation orders — a fast "
                    "civil remedy separate from filing a criminal case."
                ),
                purpose="Creates an accessible, time-bound civil remedy against domestic violence, independent of criminal prosecution.",
                punishment="Not a penal provision — the Magistrate can pass protection, residence, monetary relief, custody, and compensation orders under related sections of the Act.",
                key_elements=(
                    "Applicant must be an 'aggrieved person' in a domestic relationship facing violence.\n"
                    "Application can be filed by her, a Protection Officer, or someone on her behalf.\n"
                    "Magistrate considers the Domestic Incident Report before deciding.\n"
                    "First hearing is meant to be held within 3 days; disposal targeted within 60 days."
                ),
                relevant_information=(
                    "Proof of the domestic relationship (marriage certificate, shared household proof).\n"
                    "A documented timeline of incidents — photos, medical records, messages, police reports.\n"
                    "Whether a Domestic Incident Report has already been filed with a Protection Officer."
                ),
                relevant_documents="Domestic Incident Report, application under Section 12, medical/police records of incidents, proof of shared household or marriage.",
                keywords="domestic violence, protection order, magistrate application, dv act, section 12, abuse complaint",
                source=DV_ACT_SOURCE_NOTE,
            ),
            dict(
                law=bnss_maintenance,
                section_number="BNSS Section 144",
                title="Order for Maintenance of Wives, Children and Parents",
                legal_text=(
                    "A Magistrate of the First Class may order a person "
                    "of sufficient means who neglects or refuses to "
                    "maintain his wife (including a divorced, unremarried "
                    "wife), minor children, major children with a "
                    "disability, or an indigent parent, to pay a monthly "
                    "allowance. Non-payment can lead to a warrant for the "
                    "amount as a fine, and imprisonment of up to one "
                    "month per default, subject to a one-year limit on "
                    "claiming arrears."
                ),
                simple_explanation=(
                    "Lets a wife, child, or parent who cannot support "
                    "themselves claim monthly maintenance from a person "
                    "of sufficient means who is neglecting to support "
                    "them — a fast, religion-neutral remedy that replaced "
                    "the old CrPC Section 125."
                ),
                purpose="Prevents destitution of dependents by providing a quick, summary remedy for maintenance.",
                punishment="Not a penal provision for the underlying conduct — but non-payment of an ordered maintenance amount can lead to a fine (recovered like a warrant) and imprisonment of up to one month per default.",
                key_elements=(
                    "Applicant's inability to maintain themselves.\n"
                    "Respondent's sufficient means to pay.\n"
                    "Neglect or refusal by the respondent to maintain the applicant.\n"
                    "Relationship (wife, child, or parent) must be established.\n"
                    "A wife's claim can be barred by disqualifying conduct such as living in adultery."
                ),
                relevant_information=(
                    "Proof of relationship — marriage certificate, birth certificates.\n"
                    "Evidence of the applicant's income/inability to self-support.\n"
                    "Evidence of the respondent's income and assets.\n"
                    "Any prior maintenance order (e.g. under the Hindu Marriage Act or DV Act) to avoid double claims."
                ),
                relevant_documents="Marriage/birth certificates, income proof of both parties, any prior maintenance order, application for maintenance.",
                keywords="maintenance, alimony, wife maintenance, child maintenance, parents maintenance, bnss 144, section 125",
                source=BNSS_SOURCE_NOTE,
            ),
            dict(
                law=tpa,
                section_number="Section 54",
                title="Sale of Immovable Property Defined",
                legal_text=(
                    "Sale is a transfer of ownership in exchange for a "
                    "price paid, promised, or partly paid and partly "
                    "promised. For tangible immovable property worth Rs. "
                    "100 or more, and for any transfer of an intangible "
                    "property interest, a sale can only be made through "
                    "a registered instrument. For tangible immovable "
                    "property worth less than Rs. 100, sale may be made "
                    "either by a registered instrument or simply by "
                    "delivery of possession."
                ),
                simple_explanation=(
                    "Defines what a 'sale' of property legally is, and "
                    "says that for anything but trivially low-value "
                    "property, ownership can only be transferred through "
                    "a registered sale deed — not just by handing over "
                    "the property or signing an unregistered agreement."
                ),
                purpose="Ensures certainty of title and a documented, verifiable record of property ownership transfers, reducing fraud and disputes.",
                punishment="Not a penal provision — an unregistered document purporting to sell property worth Rs. 100 or more does not transfer ownership and generally cannot be used as evidence of title in court.",
                key_elements=(
                    "Transfer of ownership (not merely possession) in exchange for a price.\n"
                    "Price is paid, promised, or part-paid and part-promised.\n"
                    "A registered instrument is mandatory for property valued Rs. 100 or more.\n"
                    "An 'agreement to sell' is distinct from a completed sale and does not by itself transfer ownership."
                ),
                relevant_information=(
                    "Whether the sale deed is actually registered at the Sub-Registrar's office, not merely notarized.\n"
                    "The seller's title chain and whether the registered document correctly describes the property and price.\n"
                    "Whether what you have is only an 'agreement to sell', not a registered sale deed."
                ),
                relevant_documents="Registered sale deed, title documents/chain of ownership, payment proof, encumbrance certificate.",
                keywords="sale deed, property sale, transfer of ownership, agreement to sell, section 54, transfer of property act",
                source=TPA_SOURCE_NOTE,
            ),
            dict(
                law=registration_act,
                section_number="Section 17",
                title="Documents Requiring Compulsory Registration",
                legal_text=(
                    "Compulsory registration applies to gift deeds of "
                    "immovable property; non-testamentary documents worth "
                    "Rs. 100 or more that create, declare, assign, limit, "
                    "or extinguish any right, title, or interest in "
                    "immovable property; leases from year to year, "
                    "exceeding one year, or reserving a yearly rent; and "
                    "certain non-testamentary decrees or orders affecting "
                    "such rights. Since a 2001 amendment, documents "
                    "recording a contract to transfer immovable property "
                    "for consideration are also covered for "
                    "specific-performance purposes."
                ),
                simple_explanation=(
                    "Lists which property-related documents must legally "
                    "be registered with the Sub-Registrar to be valid — "
                    "including sale deeds, gift deeds, and leases longer "
                    "than a year."
                ),
                purpose="Creates a reliable public record of property transactions, preventing fraud and title disputes.",
                punishment="Not a penal provision — an unregistered document that was required to be registered cannot affect the property and generally cannot be used as evidence of the transaction in court.",
                key_elements=(
                    "Gift deeds of immovable property.\n"
                    "Non-testamentary documents worth Rs. 100+ affecting rights/title/interest in immovable property.\n"
                    "Leases from year to year, exceeding one year, or reserving yearly rent.\n"
                    "Certain contracts for transfer of immovable property (added by a 2001 amendment)."
                ),
                relevant_information=(
                    "Whether your sale/gift/lease deed is actually registered, with an entry in the Sub-Registrar's index.\n"
                    "The registration date and index-II entry, especially before purchasing property.\n"
                    "That an unregistered agreement may still matter for a specific-performance claim, but not for proving title."
                ),
                relevant_documents="Registered deed copy, index-II extract from the Sub-Registrar, encumbrance certificate.",
                keywords="document registration, sub-registrar, registration act, section 17, sale deed registration, lease registration",
                source=REGISTRATION_ACT_SOURCE_NOTE,
            ),
            dict(
                law=posh_act,
                section_number="Section 9",
                title="Complaint of Sexual Harassment",
                legal_text=(
                    "An aggrieved woman may submit a written complaint "
                    "of workplace sexual harassment to the Internal "
                    "Committee (or the Local Committee, if no Internal "
                    "Committee exists) within three months of the "
                    "incident, or the last incident in a series. If she "
                    "is unable to write the complaint herself, a "
                    "Committee member or officer must render reasonable "
                    "assistance. The Committee may extend this deadline "
                    "by up to three further months, for recorded "
                    "reasons, where circumstances prevented timely "
                    "filing."
                ),
                simple_explanation=(
                    "Lets a woman file a written complaint about "
                    "workplace sexual harassment with her employer's "
                    "Internal Committee (or a Local Committee if the "
                    "workplace has none) within three months of the "
                    "incident, extendable by up to three more months for "
                    "good reason."
                ),
                purpose="Gives women a confidential, accessible first channel to report workplace harassment without immediately going to police or court.",
                punishment="Not a penal provision itself — it governs how and when a complaint is filed; the harassment itself may separately be an offence under criminal law, and an employer's failure to constitute a required Committee is penalized under a different section of this Act.",
                key_elements=(
                    "Complainant must be a woman facing workplace sexual harassment.\n"
                    "Complaint must be in writing, with assistance available if needed.\n"
                    "Must be filed within 3 months of the incident, or last incident in a series.\n"
                    "Extendable by the Committee for up to 3 further months for recorded reasons."
                ),
                relevant_information=(
                    "Exact date(s) of the incident(s) — the time limit is strict.\n"
                    "Whether the workplace has a constituted Internal Committee, or whether the complaint should go to the district Local Committee instead.\n"
                    "Written assistance from a Committee member is a right if you cannot write the complaint yourself."
                ),
                relevant_documents="Written complaint to the Internal/Local Committee, any evidence of the incident (messages, emails, witness accounts).",
                keywords="posh act, workplace harassment, sexual harassment complaint, internal committee, section 9, icc complaint",
                source=POSH_SOURCE_NOTE,
            ),
            dict(
                law=dowry_act,
                section_number="Section 3",
                title="Penalty for Giving or Taking Dowry",
                legal_text=(
                    "Whoever gives, takes, or abets the giving or taking "
                    "of dowry shall be punished with imprisonment of not "
                    "less than five years, and with a fine of not less "
                    "than fifteen thousand rupees or the value of the "
                    "dowry, whichever is higher. A court may impose a "
                    "lesser term of imprisonment only for adequate and "
                    "special reasons recorded in its judgment. Genuinely "
                    "voluntary, non-excessive customary wedding gifts "
                    "given without any demand are exempt, provided they "
                    "are entered in a list as prescribed."
                ),
                simple_explanation=(
                    "Makes it a crime to give, take, or help arrange "
                    "dowry in connection with a marriage — covering the "
                    "giver, the taker, and anyone who helps arrange it, "
                    "with a minimum five-year jail term."
                ),
                purpose="Criminalizes the dowry system, which drives dowry-related harassment, abuse, and financial exploitation of brides' families.",
                punishment="Imprisonment of not less than 5 years (reducible only for recorded special reasons), and a fine of not less than Rs. 15,000 or the dowry's value, whichever is greater.",
                key_elements=(
                    "Dowry (as defined by the Act) was given, taken, or demanded in connection with a marriage.\n"
                    "Applies equally to the person giving, the person taking, and anyone abetting.\n"
                    "A genuinely voluntary, listed customary gift given without any demand is exempt."
                ),
                relevant_information=(
                    "Any written or recorded evidence of a dowry demand (messages, lists, witness accounts).\n"
                    "Whether related complaints exist under cruelty/dowry-death provisions of criminal law, since these often run alongside a Section 3 complaint.\n"
                    "The 1986 amendment's five-year minimum is the current governing penalty — older sources citing a six-month term are outdated."
                ),
                relevant_documents="Written record of the dowry demand, wedding gift list (if any), police complaint, any related cruelty/dowry-death FIR.",
                keywords="dowry, dowry prohibition act, dowry demand, dowry harassment, section 3, giving taking dowry",
                source=DOWRY_SOURCE_NOTE,
            ),
            dict(
                law=pocso,
                section_number="Section 4",
                title="Punishment for Penetrative Sexual Assault",
                legal_text=(
                    "Whoever commits penetrative sexual assault on a "
                    "child shall be punished with imprisonment of not "
                    "less than ten years, extendable to imprisonment for "
                    "life, and a fine. If the child is below sixteen "
                    "years of age, the minimum term is twenty years, "
                    "extendable to imprisonment for the remainder of the "
                    "offender's natural life, and a fine. Fine amounts "
                    "must be just and reasonable, and are payable to the "
                    "victim for medical treatment and rehabilitation."
                ),
                simple_explanation=(
                    "Punishes penetrative sexual assault against a child "
                    "(under 18) with a minimum of 10 years' imprisonment, "
                    "rising to a minimum of 20 years if the child is "
                    "under 16 — these minimums were raised by a 2019 "
                    "amendment."
                ),
                purpose="Deters and severely punishes penetrative sexual abuse of children, reflecting the 2019 amendment's tightening of minimum sentences.",
                punishment="Minimum 10 years' imprisonment, extendable to life, and fine; if the victim is under 16, minimum 20 years, extendable to imprisonment for the remainder of the offender's natural life, and fine.",
                key_elements=(
                    "Act meets the statutory definition of 'penetrative sexual assault'.\n"
                    "Victim is a 'child' — under 18 years of age under this Act.\n"
                    "Victim's exact age (under/over 16) determines which minimum sentence applies."
                ),
                relevant_information=(
                    "Report to the local police or Special Juvenile Police Unit (SJPU) — reporting is mandatory for anyone aware of the offence.\n"
                    "POCSO cases are tried in a designated Special Court with child-friendly, in-camera procedures.\n"
                    "This section is distinct from 'aggravated' penetrative sexual assault (a separate, more severe section) — do not confuse the two."
                ),
                relevant_documents="FIR / complaint to SJPU or police, medical examination report, Child Welfare Committee records.",
                keywords="pocso, child sexual assault, child abuse law, penetrative sexual assault, section 4, child protection",
                source=POCSO_SOURCE_NOTE,
            ),
            dict(
                law=pocso,
                section_number="Section 19 & 21",
                title="Mandatory Reporting of Child Sexual Abuse",
                legal_text=(
                    "Any person who has knowledge or reasonable "
                    "apprehension that an offence under this Act has "
                    "occurred, including the child concerned, must "
                    "inform the Special Juvenile Police Unit or the "
                    "local police. Reports must be recorded in writing, "
                    "given an entry number, and read back to the "
                    "informant. Failure to report or record such "
                    "information is punishable with imprisonment up to "
                    "six months, or fine, or both; a person in charge of "
                    "a company or institution who fails to report an "
                    "offence by a subordinate faces up to one year's "
                    "imprisonment and a fine. Children are exempt from "
                    "this penalty."
                ),
                simple_explanation=(
                    "Makes it a legal duty for anyone who knows or "
                    "suspects a child sexual offence has happened to "
                    "report it to the police or SJPU — and failing to do "
                    "so is itself punishable, with a harsher penalty for "
                    "institutional heads who fail to report a "
                    "subordinate's offence."
                ),
                purpose="Overcomes silence and institutional inaction around child sexual abuse by making reporting a duty for everyone, not just the victim or family.",
                punishment="Failure to report or record: up to 6 months' imprisonment, or fine, or both. An institutional head failing to report a subordinate's offence: up to 1 year's imprisonment and fine. Children are exempt from this penalty.",
                key_elements=(
                    "Reporter had actual knowledge or reasonable apprehension of an offence.\n"
                    "Failure was to report to the SJPU or police — not merely to a superior.\n"
                    "For the higher penalty, the accused must be an institutional head with a subordinate who committed the offence.\n"
                    "Genuine, good-faith reports carry civil and criminal immunity for the informant."
                ),
                relevant_information=(
                    "A report can be made without your identity being made public.\n"
                    "Police must forward the report to the Child Welfare Committee or Special Court within 24 hours.\n"
                    "False or malicious complaints are separately punishable under a different section — this reporting duty only concerns genuine suspicion."
                ),
                relevant_documents="Written report to SJPU/police with entry number, Child Welfare Committee referral record.",
                keywords="pocso reporting, mandatory reporting child abuse, section 19, section 21, failure to report, child protection",
                source=POCSO_SOURCE_NOTE,
            ),
            dict(
                law=css,
                section_number="Section 60",
                title="Right to Payment of Maternity Benefit",
                legal_text=(
                    "Every woman is entitled to, and her employer is "
                    "liable for, payment of maternity benefit at the "
                    "rate of her average daily wage for the period of "
                    "her actual absence — 26 weeks for a woman with "
                    "fewer than two surviving children (of which not "
                    "more than 8 weeks may be taken before the expected "
                    "delivery date), and 12 weeks for a woman with two "
                    "or more surviving children. Eligibility requires "
                    "having worked for the employer for at least 80 "
                    "days in the 12 months before the expected delivery "
                    "date."
                ),
                simple_explanation=(
                    "Gives a working woman the right to paid maternity "
                    "leave — 26 weeks if she has fewer than two "
                    "surviving children, or 12 weeks otherwise — "
                    "provided she has worked at least 80 days in the "
                    "preceding year. This is the direct successor to "
                    "the old Maternity Benefit Act, folded into the new "
                    "labour codes that took effect in November 2025."
                ),
                purpose="Protects women's health and income security around childbirth and discourages workplace discrimination against pregnant employees.",
                punishment="Not a penal provision for the woman — an employer who denies this benefit is liable for prosecution/penalty under the Code, and the benefit can be claimed via labour authorities or courts.",
                key_elements=(
                    "Worked at least 80 days for the employer in the 12 months before the expected delivery date.\n"
                    "Employer covered by the Code on Social Security.\n"
                    "Leave duration depends on the number of surviving children (26 weeks or 12 weeks).\n"
                    "Dismissal during maternity leave is generally barred."
                ),
                relevant_information=(
                    "Proof of continuous employment and expected delivery date (doctor's certificate).\n"
                    "Employer's establishment size and whether it is covered under the Code.\n"
                    "Some state-level procedural rules under the new labour codes were still being finalized through 2026, which may affect enforcement details in a given state."
                ),
                relevant_documents="Employment records, medical certificate confirming pregnancy/expected delivery date, written maternity benefit claim to the employer.",
                keywords="maternity leave, maternity benefit, pregnancy workplace rights, 26 weeks leave, code on social security, section 60",
                source=CSS_SOURCE_NOTE,
            ),
            dict(
                law=ir_code,
                section_number="Section 70",
                title="Conditions Precedent to Retrenchment of Workers",
                legal_text=(
                    "A worker who has been in continuous service for at "
                    "least one year cannot be retrenched until given "
                    "one month's written notice (or wages in lieu of "
                    "notice), paid compensation equivalent to fifteen "
                    "days' average pay for every completed year of "
                    "continuous service (or any part exceeding six "
                    "months), and until notice is served on the "
                    "appropriate Government or authority."
                ),
                simple_explanation=(
                    "Before an employer can retrench (lay off) a worker "
                    "with at least a year of continuous service, it must "
                    "give one month's notice or pay in lieu, pay "
                    "retrenchment compensation of 15 days' average pay "
                    "per completed year of service, and notify the "
                    "government. This is the direct successor to the "
                    "old Industrial Disputes Act's Section 25F, folded "
                    "into the new labour codes that took effect in "
                    "November 2025."
                ),
                purpose="Prevents arbitrary job loss and cushions workers financially during involuntary termination unrelated to misconduct.",
                punishment="Not a penal provision defining a crime — but retrenchment carried out without meeting these conditions can be declared illegal/void, and the Industrial Tribunal may order reinstatement with back wages.",
                key_elements=(
                    "Worker has at least one year of continuous service.\n"
                    "One month's written notice or pay in lieu of notice was given.\n"
                    "Retrenchment compensation (15 days' average pay per completed year) was actually paid.\n"
                    "Notice was served on the appropriate Government or authority."
                ),
                relevant_information=(
                    "Length of continuous service with the employer.\n"
                    "Whether notice and compensation were actually paid, and when.\n"
                    "Whether the organization's size triggers additional government-permission requirements for larger establishments."
                ),
                relevant_documents="Employment/service records, retrenchment notice, compensation payment proof, correspondence with labour authorities.",
                keywords="retrenchment, layoff, termination, industrial relations code, section 70, notice pay, compensation",
                source=IR_CODE_SOURCE_NOTE,
            ),
        ]

        section_by_number = {}

        for data in sections:
            obj, _ = LegalSection.objects.update_or_create(
                law=data["law"],
                section_number=data["section_number"],
                defaults={**data, "last_verified": WEBSITE_PORT_VERIFIED},
            )
            section_by_number[data["section_number"]] = obj

        for data in rights_sections:
            obj, _ = LegalSection.objects.update_or_create(
                law=data["law"],
                section_number=data["section_number"],
                defaults={**data, "last_verified": WEBSITE_PORT_VERIFIED},
            )
            section_by_number[data["section_number"]] = obj

        for data in website_port_sections:
            obj, _ = LegalSection.objects.update_or_create(
                law=data["law"],
                section_number=data["section_number"],
                defaults={**data, "last_verified": WEBSITE_PORT_VERIFIED},
            )
            section_by_number[data["section_number"]] = obj

        for data in new_categories_sections:
            obj, _ = LegalSection.objects.update_or_create(
                law=data["law"],
                section_number=data["section_number"],
                defaults={**data, "last_verified": NEW_CATEGORIES_VERIFIED},
            )
            section_by_number[data["section_number"]] = obj

        # --- Cross-links between related sections (mirrors the relationships
        # already surfaced in the source website's data). ---
        related_links = {
            "Section 303": ["Section 304", "Section 309", "Section 316"],
            "Section 304": ["Section 303", "Section 309"],
            "Section 309": ["Section 303", "Section 318"],
            "Section 318": ["Section 316", "Section 66D"],
            "Section 316": ["Section 318", "Section 303"],
            "Section 351": ["Section 115", "Section 356"],
            "Section 115": ["Section 351"],
            "Section 356": ["Section 351", "Section 66D"],
            "Section 74": ["Section 351", "Section 9"],
            "Section 66D": ["Section 318", "Section 66C"],
            "Section 66C": ["Section 66D"],
            "BNSS Section 35": ["BNSS Section 47"],
            "BNSS Section 47": ["BNSS Section 35"],
            "Section 185": ["Section 115"],
            "Section 13": ["BNSS Section 144", "Section 12"],
            "Section 12": ["BNSS Section 144", "Section 13", "Section 3"],
            "BNSS Section 144": ["Section 13", "Section 12"],
            "Section 54": ["Section 17"],
            "Section 17": ["Section 54"],
            "Section 9": ["Section 74"],
            "Section 3": ["Section 12"],
            "Section 4": ["Section 19 & 21"],
            "Section 19 & 21": ["Section 4"],
        }
        for number, related_numbers in related_links.items():
            section = section_by_number.get(number)
            if not section:
                continue
            related = [section_by_number[n] for n in related_numbers if n in section_by_number]
            section.related_sections.set(related)

        # --- Legal Matters: real ones link to already-sourced sections;
        # unpopulated ones are real topic *names* only (no invented legal
        # text) and render as "coming soon" in the app. ---
        matters = [
            dict(category=criminal_law, name="Arrest", description=(
                "What happens when someone is arrested, and the rights that "
                "apply during the process."
            ), section_numbers=[
                "BNSS Section 35", "BNSS Section 47", "BNSS Section 48",
                "BNSS Section 43(5)", "BNSS Section 58", "Article 22(1)",
            ]),
            dict(category=criminal_law, name="Theft & Snatching", description=(
                "Taking someone else's property without consent, whether "
                "stealthily or by sudden/forcible grabbing."
            ), section_numbers=["Section 303", "Section 304"]),
            dict(category=criminal_law, name="Cheating & Fraud", description=(
                "Being deceived into handing over money, property, or "
                "documents, or entrusted property being misappropriated."
            ), section_numbers=["Section 318", "Section 316"]),
            dict(category=criminal_law, name="Robbery", description="",
                 section_numbers=["Section 309"]),
            dict(category=criminal_law, name="Assault & Hurt", description="",
                 section_numbers=["Section 115"]),
            dict(category=criminal_law, name="Criminal Intimidation", description="",
                 section_numbers=["Section 351"]),
            dict(category=criminal_law, name="Defamation", description="",
                 section_numbers=["Section 356"]),
            dict(category=criminal_law, name="Murder", description="",
                 section_numbers=["Section 103(1)"]),
            dict(category=criminal_law, name="Bail", description="", section_numbers=[]),
            dict(category=criminal_law, name="FIR", description="", section_numbers=[]),
            dict(category=criminal_law, name="Criminal complaint", description="", section_numbers=[]),
            dict(category=criminal_law, name="Search and seizure", description="", section_numbers=[]),
            dict(category=criminal_law, name="Investigation", description="", section_numbers=[]),
            dict(category=criminal_law, name="Evidence", description="", section_numbers=[]),
            dict(category=criminal_law, name="Summons", description="", section_numbers=[]),
            dict(category=criminal_law, name="Warrant", description="", section_numbers=[]),
            dict(category=criminal_law, name="Trial", description="", section_numbers=[]),
            dict(category=constitutional_law, name="Right to Life & Liberty", description="",
                 section_numbers=["Article 21"]),
            dict(category=constitutional_law, name="Right to Legal Counsel", description="",
                 section_numbers=["Article 22(1)"]),
            dict(category=categories_by_name["Family Law"], name="Marriage", description="", section_numbers=[]),
            dict(category=categories_by_name["Family Law"], name="Divorce", description="",
                 section_numbers=["Section 13"]),
            dict(category=categories_by_name["Family Law"], name="Maintenance", description="",
                 section_numbers=["BNSS Section 144"]),
            dict(category=categories_by_name["Family Law"], name="Domestic violence", description="",
                 section_numbers=["Section 12"]),
            dict(category=categories_by_name["Family Law"], name="Child custody", description="", section_numbers=[]),
            dict(category=categories_by_name["Family Law"], name="Adoption", description="", section_numbers=[]),
            dict(category=categories_by_name["Family Law"], name="Inheritance", description="", section_numbers=[]),
            dict(category=categories_by_name["Property Law"], name="Property ownership", description="", section_numbers=[]),
            dict(category=categories_by_name["Property Law"], name="Rent disputes", description="", section_numbers=[]),
            dict(category=categories_by_name["Property Law"], name="Sale of property", description="",
                 section_numbers=["Section 54"]),
            dict(category=categories_by_name["Property Law"], name="Registration", description="",
                 section_numbers=["Section 17"]),
            dict(category=categories_by_name["Property Law"], name="Property documents", description="", section_numbers=[]),
            dict(category=categories_by_name["Property Law"], name="Land disputes", description="", section_numbers=[]),
            dict(category=consumer_law, name="Consumer complaints", description=(
                "How to file a complaint before the District Consumer Commission."
            ), section_numbers=["Section 35"]),
            dict(category=consumer_law, name="Defective products", description="", section_numbers=[]),
            dict(category=consumer_law, name="Deficiency in service", description="", section_numbers=[]),
            dict(category=consumer_law, name="Refunds", description="", section_numbers=[]),
            dict(category=consumer_law, name="Consumer forums", description="", section_numbers=[]),
            dict(category=motor_vehicle_law, name="Drunk driving", description="",
                 section_numbers=["Section 185"]),
            dict(category=motor_vehicle_law, name="Traffic violations", description="", section_numbers=[]),
            dict(category=motor_vehicle_law, name="Accident claims", description="", section_numbers=[]),
            dict(category=motor_vehicle_law, name="Driving license", description="", section_numbers=[]),
            dict(category=motor_vehicle_law, name="Vehicle registration", description="", section_numbers=[]),
            dict(category=womens_rights, name="Assault on Modesty / Harassment", description="",
                 section_numbers=["Section 74"]),
            dict(category=womens_rights, name="Domestic violence protection", description="",
                 section_numbers=["Section 12"]),
            dict(category=womens_rights, name="Workplace harassment", description="",
                 section_numbers=["Section 9"]),
            dict(category=womens_rights, name="Maintenance rights", description="",
                 section_numbers=["BNSS Section 144"]),
            dict(category=womens_rights, name="Dowry harassment", description="",
                 section_numbers=["Section 3"]),
            dict(category=categories_by_name["Child Protection"], name="Child labour protection", description="", section_numbers=[]),
            dict(category=categories_by_name["Child Protection"], name="Juvenile justice", description="", section_numbers=[]),
            dict(category=categories_by_name["Child Protection"], name="Right to education", description="", section_numbers=[]),
            dict(category=categories_by_name["Child Protection"], name="Child sexual abuse protection", description="",
                 section_numbers=["Section 4", "Section 19 & 21"]),
            dict(category=categories_by_name["Labour & Employment"], name="Wages", description="", section_numbers=[]),
            dict(category=categories_by_name["Labour & Employment"], name="Industrial disputes", description="", section_numbers=[]),
            dict(category=categories_by_name["Labour & Employment"], name="Workplace safety", description="", section_numbers=[]),
            dict(category=categories_by_name["Labour & Employment"], name="Termination", description="",
                 section_numbers=["Section 70"]),
            dict(category=categories_by_name["Labour & Employment"], name="Maternity benefits", description="",
                 section_numbers=["Section 60"]),
            dict(category=cyber_law, name="Online financial fraud", description=(
                "Being tricked online, over the phone, or via a fake profile "
                "into transferring money or sharing credentials."
            ), section_numbers=["Section 66D"]),
            dict(category=cyber_law, name="Identity theft", description=(
                "Someone using your password, digital signature, or other "
                "unique identifier without permission."
            ), section_numbers=["Section 66C"]),
            dict(category=cyber_law, name="Cyber harassment", description="", section_numbers=[]),
            dict(category=cyber_law, name="Data/privacy issues", description="", section_numbers=[]),
            dict(category=cyber_law, name="Cyber complaints", description="", section_numbers=[]),
        ]

        matters_created = 0
        for m in matters:
            matter, _ = LegalMatter.objects.update_or_create(
                category=m["category"],
                name=m["name"],
                defaults={"description": m["description"]},
            )
            linked = [section_by_number[num] for num in m["section_numbers"] if num in section_by_number]
            matter.related_sections.set(linked)
            matters_created += 1

        total = (
            len(sections) + len(rights_sections) + len(website_port_sections)
            + len(new_categories_sections)
        )
        self.stdout.write(self.style.SUCCESS(
            f"Seeded {total} real, source-cited legal sections, "
            f"{len(categories_by_name)} categories, and {matters_created} matters "
            f"({sum(1 for m in matters if m['section_numbers'] or m['description'])} populated)."
        ))
