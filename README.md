# showrate

My organization had a relatively high no-show rate, which caused lost revenue and less appointment availability for other patients, so I wanted to put together a data study to attempt to identify factors that may indicate whether a patient would miss an appointment or not.

Utilizing both and R, I evaluated various factors such as age, gender, race/ethnicity, type of appointment, appointment day of the week, etc. The study was performed on over 500K patients and the various factors weighted against each other for importance.

Once this was completed, the top six most influential were selected and a model was developed utilizing Random Forest and applied to all future appointment in an attempt to predict how many no-shows there would. The model proved to be around 91% accurate and allowed the organization to more accurately overbook where necessary to keep the clinics at capacity and improve revenue.
